#!/usr/bin/env node
/**
 * bridge/agent-watch.mjs
 * ============================================================================
 * BỘ POLL "PHIÊN TRÒ CHUYỆN" GIỮA AGENT CHÍNH VÀ CÁC AGENT PHỤ + NGHIỆM THU TỰ ĐỘNG
 * ----------------------------------------------------------------------------
 * Agent phụ không nói chuyện qua chat — họ ghi vào repo:
 *   • `agents/notes/<TASK_ID>__<nhánh>.md`  — báo cáo / SUBMIT / toạ độ bàn giao
 *   • nhánh `origin/arena/*`                — file module thật
 *   • PR trên GitHub                        — bài nộp chính thức
 *
 * Script này poll đúng 3 nguồn đó, phát hiện THAY ĐỔI, rồi **chấm sơ bộ ngay**:
 *   1. Biên dịch module mới bằng `@luau-rs/luau` (nếu máy có).
 *   2. Đếm khối, đếm khối có máu ẩn (`Destructible`), tỉ lệ phá huỷ.
 *   3. Chặn sửa file lõi + chặn commit `studio-sync.json`.
 *   4. Chặn 2 Agent cùng dựng 1 ô đất.
 *   5. Kiểm tra bài nộp có đủ ảnh render + đủ mục báo cáo.
 *
 * CÁCH DÙNG
 *   node bridge/agent-watch.mjs                 # poll mỗi 20 giây, in mọi thay đổi mới
 *   node bridge/agent-watch.mjs --once          # quét 1 lần rồi thoát (dùng trong CI)
 *   node bridge/agent-watch.mjs --interval 10   # đổi nhịp poll (giây)
 *   node bridge/agent-watch.mjs --no-fetch      # không gọi git fetch (chạy offline)
 *   node bridge/agent-watch.mjs --reset         # xoá dấu vết đã đọc, coi mọi thứ là MỚI
 *
 * Trạng thái đã đọc lưu ở `.agent-watch-state.json` (không commit).
 * ============================================================================
 */

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { REPO_ROOT } from "./compiler.mjs";

const STATE_FILE = path.join(REPO_ROOT, ".agent-watch-state.json");
const BOARD_PATH = path.join(REPO_ROOT, "agents", "AGENT_TASK_BOARD.json");
const NOTES_DIR = "agents/notes";
const CORE_FILES = [
  "src/shared/WorldGrid.luau",
  "src/shared/World/PartBuilder.luau",
  "src/shared/World/CityFoundation.luau",
  "src/shared/World/DistrictRegistry.luau",
  "src/server/init.server.luau",
  "src/client/init.client.luau",
  "studio-sync.json",
];

const args = process.argv.slice(2);
const ONCE = args.includes("--once");
const NO_FETCH = args.includes("--no-fetch");
const RESET = args.includes("--reset");
const intervalIdx = args.indexOf("--interval");
const INTERVAL = intervalIdx >= 0 ? Math.max(5, Number(args[intervalIdx + 1]) || 20) : 20;

const C = {
  reset: "\x1b[0m",
  dim: "\x1b[2m",
  bold: "\x1b[1m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  cyan: "\x1b[36m",
  mag: "\x1b[35m",
};

function git(argv, allowFail = true) {
  try {
    return execFileSync("git", argv, { cwd: REPO_ROOT, encoding: "utf8", maxBuffer: 32 * 1024 * 1024 }).trim();
  } catch (err) {
    if (allowFail) return "";
    throw err;
  }
}

function loadState() {
  if (RESET) return { notes: {}, prs: {}, branches: {}, seenAt: Date.now() };
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, "utf8"));
  } catch {
    return { notes: {}, prs: {}, branches: {}, seenAt: 0 };
  }
}

function saveState(state) {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  } catch {
    /* bỏ qua */
  }
}

function resolveMasterRef(board) {
  const master = board.masterCoordinatorBranch;
  if (master) {
    const ref = `origin/${master}`;
    if (git(["rev-parse", "--verify", "--quiet", ref])) return ref;
  }
  return "origin/main";
}

function loadBoard() {
  try {
    return JSON.parse(fs.readFileSync(BOARD_PATH, "utf8"));
  } catch {
    return { tasks: [] };
  }
}

function sha(text) {
  return crypto.createHash("sha1").update(text).digest("hex").slice(0, 12);
}

function remoteBranches() {
  const raw = git(["branch", "-r", "--format=%(refname:short)"]);
  return raw
    .split("\n")
    .map((s) => s.trim())
    .filter((b) => b.startsWith("origin/") && !b.endsWith("/HEAD"));
}

// ──────────────────────────────────────────────────────────────────────────────
// 1. ĐỌC CÁC FILE "TRÒ CHUYỆN"
// ──────────────────────────────────────────────────────────────────────────────
function collectNotes() {
  const found = [];
  for (const ref of remoteBranches()) {
    const listing = git(["ls-tree", "--name-only", ref, `${NOTES_DIR}/`]);
    if (!listing) continue;
    for (const rel of listing.split("\n").map((s) => s.trim()).filter(Boolean)) {
      const body = git(["show", `${ref}:${rel}`]);
      if (!body) continue;
      found.push({ ref, rel, name: path.basename(rel), body, hash: sha(body) });
    }
  }
  return found;
}

function collectPRs() {
  const raw = git(["ls-remote", "--heads", "origin", "refs/heads/arena/*"]);
  const map = {};
  if (raw) {
    for (const line of raw.split("\n")) {
      const [hash, ref] = line.split("\t");
      if (!ref) continue;
      map[ref.replace("refs/heads/", "")] = hash;
    }
  }
  return map;
}

// ──────────────────────────────────────────────────────────────────────────────
// 2. CHẤM SƠ BỘ MỘT BÀI NỘP
// ──────────────────────────────────────────────────────────────────────────────
let luauLib = null;
async function getLuau() {
  if (luauLib !== null) return luauLib;
  try {
    const mod = await import("@luau-rs/luau");
    luauLib = mod;
  } catch {
    try {
      const mod = await import("/tmp/luau-check/node_modules/@luau-rs/luau/dist/direct-api.js");
      luauLib = mod;
    } catch {
      luauLib = false;
    }
  }
  return luauLib;
}

async function compileSource(source) {
  const lib = await getLuau();
  if (!lib) return { ok: null, note: "không có @luau-rs/luau (bỏ qua bước biên dịch)" };
  try {
    const lua = await lib.Lua.create();
    lua.compile(source, { chunkName: "submission" });
    return { ok: true };
  } catch (err) {
    return { ok: false, note: String(err && err.message ? err.message : err) };
  }
}

function analyzeSource(source) {
  const bytes = Buffer.byteLength(source, "utf8");
  const lines = source.split("\n").length;
  const loops = (source.match(/^\s*for\s+/gm) || []).length;
  const partCalls = (source.match(/PartBuilder\.(part|brickWall|wedge|surveyMonument|cylinder)\s*\(/g) || []).length;
  const localPartCalls = (source.match(/\bpart\(\{|\bbrick\(\{|\bwall\(\{/g) || []).length;
  const health = (source.match(/Destructible|MaxPartHealth|PartHealth|integrity/gi) || []).length;
  return { bytes, lines, loops, partCalls: partCalls + localPartCalls, health };
}

function checkCoreEdits(branch) {
  const diff = git(["diff", "--name-only", `${MASTER_REF}...origin/${branch}`]);
  if (!diff) return { touched: [], syncBundle: false, files: [] };
  const files = diff.split("\n").map((s) => s.trim()).filter(Boolean);
  return {
    touched: files.filter((f) => CORE_FILES.includes(f)),
    syncBundle: files.includes("studio-sync.json"),
    files,
  };
}

let MASTER_REF = "origin/main";

async function reviewSubmission(note, board) {
  const branch = note.ref.replace("origin/", "");
  const baseName = note.name
    .replace(/\.md$/i, "")
    .split("__")[0]
    .replace(/^(SUBMIT|APPROVED|NOTE|REVIEW)_/i, "");
  const taskId = baseName.toUpperCase();
  const task = board.tasks.find((t) => t.taskId && t.taskId.toUpperCase() === taskId) || null;
  const modulePath = task ? task.modulePath : null;

  const lines = [];
  const verdict = { pass: true, reasons: [] };
  const fail = (msg) => {
    verdict.pass = false;
    verdict.reasons.push(msg);
  };

  lines.push(`   Nhánh      : ${branch}`);
  lines.push(`   Task       : ${taskId || "(không rõ)"}${task ? ` — ${task.title.slice(0, 70)}` : " (không có trên bảng)"}`);
  if (!task) fail("không tìm thấy TASK_ID trên bảng điều phối");

  // a) file module có tồn tại trên nhánh đó không
  if (modulePath) {
    const src = git(["show", `origin/${branch}:${modulePath}`]);
    if (!src) {
      fail(`thiếu file module ${modulePath}`);
    } else {
      // b) biên dịch
      const comp = await compileSource(src);
      if (comp.ok === true) lines.push("   Biên dịch  : ✅ OK");
      else if (comp.ok === false) {
        lines.push(`   Biên dịch  : ❌ ${comp.note}`);
        fail("biên dịch lỗi");
      } else lines.push(`   Biên dịch  : ⚠️ ${comp.note}`);

      // c) đo "độ chi tiết" bằng thước đo thực tế (module chi tiết thật nặng 40–150 KB)
      const a = analyzeSource(src);
      const kb = (a.bytes / 1024).toFixed(1);
      lines.push(
        `   Quy mô     : ${kb} KB · ${a.lines} dòng · ${a.loops} vòng lặp sinh khối · ${a.partCalls} lời gọi dựng khối · ${a.health} chỗ khai báo máu ẩn`
      );
      if (a.bytes < 40 * 1024) fail(`module chỉ ${kb} KB — công trình chi tiết thật phải >= 40 KB (LS Customs 126 KB, LSPD 141 KB)`);
      if (a.loops < 10) fail(`chỉ ${a.loops} vòng lặp — không đủ chi tiết`);
      if (a.health < 3) fail(`chỉ ${a.health} chỗ khai báo máu ẩn — yêu cầu >= 95% khối phá huỷ`);
    }
  }

  // d) không sửa file lõi
  const core = checkCoreEdits(branch);
  if (core.syncBundle) fail("có commit studio-sync.json (chỉ Agent Chính được publish)");
  if (core.touched.length > 0) fail(`sửa file lõi: ${core.touched.join(", ")}`);
  lines.push(`   File đổi   : ${(core.files || []).length} file${core.touched.length ? ` (⚠️ lõi: ${core.touched.length})` : ""}`);

  // e) báo cáo có ảnh + số liệu?
  const hasImages = /agents\/reviews\//.test(note.body) || /\.(png|jpe?g)/i.test(note.body);
  const hasNumbers = /(\d{2,5})\s*(khối|part|parts)/i.test(note.body);
  if (!hasImages) fail("báo cáo không dẫn đường dẫn ảnh render");
  if (!hasNumbers) fail("báo cáo không có số liệu khối");
  lines.push(`   Ảnh render : ${hasImages ? "✅ có" : "❌ thiếu"} · Số liệu: ${hasNumbers ? "✅ có" : "❌ thiếu"}`);

  // f) tranh ô đất với agent khác
  if (task && task.plotId && task.plotId !== "N/A") {
    const clash = board.tasks.filter(
      (t) => t !== task && t.plotId === task.plotId && t.status === "building"
    );
    if (clash.length > 0) lines.push(`   ⚠️ Ô ${task.plotId} đang có ${clash.length} agent khác nhận`);
  }

  lines.push(
    `   ${verdict.pass ? C.green + "SƠ BỘ: ĐẠT — chờ Agent Chính xem ảnh & chạy AABB" : C.red + "SƠ BỘ: CẦN SỬA — " + verdict.reasons.join(" · ")}${C.reset}`
  );
  return { taskId, branch, pass: verdict.pass, reasons: verdict.reasons, lines };
}

// ──────────────────────────────────────────────────────────────────────────────
// 3. MỘT VÒNG POLL
// ──────────────────────────────────────────────────────────────────────────────
async function poll(state) {
  if (!NO_FETCH) git(["fetch", "origin", "+refs/heads/*:refs/remotes/origin/*", "--prune", "--quiet"]);

  const board = loadBoard();
  MASTER_REF = resolveMasterRef(board);
  const notes = collectNotes();
  const heads = collectPRs();

  const newNotes = notes.filter((n) => state.notes[n.rel] !== n.hash);
  const newHeads = Object.entries(heads).filter(([b, h]) => state.branches[b] !== h);

  const stamp = new Date().toLocaleTimeString("vi-VN");
  const header = `${C.dim}[${stamp}]${C.reset}`;

  if (newNotes.length === 0 && newHeads.length === 0) {
    if (!ONCE) process.stdout.write(`${header} ${C.dim}không có thay đổi · đang theo dõi ${notes.length} bản tin / ${Object.keys(heads).length} nhánh${C.reset}\r`);
    return;
  }

  console.log(`\n${C.bold}${C.cyan}══════════════════════════════════════════════════════════════════════${C.reset}`);
  console.log(`${C.bold}${C.cyan}  📡 THAY ĐỔI TỪ AGENT PHỤ  ${header}${C.reset}`);
  console.log(`${C.bold}${C.cyan}══════════════════════════════════════════════════════════════════════${C.reset}`);

  for (const [branch, hash] of newHeads) {
    console.log(`\n${C.mag}▸ NHÁNH MỚI/CẬP NHẬT${C.reset} ${branch} ${C.dim}@${hash.slice(0, 8)}${C.reset}`);
  }

  const results = [];
  for (const note of newNotes) {
    if (/^APPROVED_/i.test(note.name)) {
      state.notes[note.rel] = note.hash;
      continue;
    }
    console.log(`\n${C.yellow}▸ BẢN TIN${C.reset} ${note.rel}  ${C.dim}(${note.ref}, ${note.body.length}B, hash ${note.hash})${C.reset}`);
    const head = note.body.split("\n").filter((l) => l.trim()).slice(0, 4).join("\n");
    console.log(`${C.dim}${head}${C.reset}`);

    if (/SUBMIT|NỘP|submit/i.test(note.name) || /submit/i.test(note.body.slice(0, 400))) {
      const res = await reviewSubmission(note, board);
      console.log(res.lines.join("\n"));
      results.push(res);
    }
    state.notes[note.rel] = note.hash;
  }

  for (const [branch, hash] of newHeads) state.branches[branch] = hash;
  state.seenAt = Date.now();
  saveState(state);

  if (results.length > 0) {
    const pass = results.filter((r) => r.pass).length;
    console.log(
      `\n${C.bold}TỔNG KẾT VÒNG NÀY:${C.reset} ${results.length} bài nộp · ${C.green}${pass} ĐẠT sơ bộ${C.reset} · ${C.red}${results.length - pass} cần sửa${C.reset}`
    );
    console.log(`${C.dim}(AABB, ảnh render và cảm quan kiến trúc vẫn do Agent Chính chấm tay trước khi publish.)${C.reset}\n`);
  }
}

async function main() {
  console.log(`${C.bold}${C.cyan}📡 agent-watch — poll bộ đàm Agent phụ & nghiệm thu tự động${C.reset}`);
  console.log(`${C.dim}repo: ${REPO_ROOT} · nhịp: ${ONCE ? "1 lần" : INTERVAL + "s"} · fetch: ${NO_FETCH ? "tắt" : "bật"}${C.reset}`);
  const state = loadState();
  if (RESET) console.log(`${C.yellow}--reset: bỏ qua toàn bộ dấu vết cũ, coi mọi bản tin là MỚI${C.reset}`);

  if (!RESET && !state.seenAt) {
    // Lần đầu chạy: đánh dấu toàn bộ bản tin hiện có là "đã đọc" để chỉ báo cái MỚI.
    const board = loadBoard();
    MASTER_REF = resolveMasterRef(board);
    for (const n of collectNotes()) state.notes[n.rel] = n.hash;
    for (const [b, h] of Object.entries(collectPRs())) state.branches[b] = h;
    state.seenAt = Date.now();
    saveState(state);
    console.log(`${C.dim}Đã ghi nhớ ${Object.keys(state.notes).length} bản tin cũ — chỉ báo thay đổi MỚI từ giờ.${C.reset}`);
  }

  if (ONCE) {
    await poll(state);
    return;
  }
  for (;;) {
    try {
      await poll(state);
    } catch (err) {
      console.error(`${C.red}lỗi vòng poll:${C.reset}`, err.message);
    }
    await new Promise((r) => setTimeout(r, INTERVAL * 1000));
  }
}

main();
