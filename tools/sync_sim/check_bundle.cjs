/**
 * Kiểm tra GÓI SYNC mà Studio thật sự nhận được (studio-sync.json).
 *
 *   node tools/sync_sim/check_bundle.cjs          # kiểm tra file đã commit
 *   node tools/sync_sim/check_bundle.cjs --fresh  # biên dịch lại từ repo rồi kiểm tra
 *
 * Đây là bài test sinh ra để chặn đúng lỗi v24→v28: publish đẩy 40 file Rojo lên
 * nhưng `actions` RỖNG, nên Studio chỉ nhận ModuleScript mới mà không có lệnh
 * dựng lại → mở Studio ra vẫn y hệt bản cũ dù đã "đồng bộ thành công".
 *
 * Nó kiểm:
 *   1. Có ít nhất 1 tác vụ dựng thành phố (code có gọi DistrictRegistry).
 *   2. Mọi module trong src/shared/World/Modules/*.luau đều có mặt trong gói và
 *      mã nguồn trong gói == mã nguồn trên đĩa (CDN không bị cũ).
 *   3. Không thiếu file nào của src/ (Rojo) — chặn trường hợp thêm file mà quên.
 *   4. Gói có `hash` + `version` để plugin biết phải nạp lại.
 */
const fs = require("fs");
const path = require("path");
const { pathToFileURL } = require("url");

const REPO = path.resolve(__dirname, "..", "..");
const read = (p) => fs.readFileSync(p, "utf8");
const problems = [];
const okAll = [];
const warnAll = [];

function ok(msg) {
  okAll.push(msg);
}
function bad(msg) {
  problems.push(msg);
}

/** Duyệt cây services của bundle → map "Source.dotted.path" -> source */
function flattenSources(node, prefix, out) {
  for (const [name, spec] of Object.entries(node || {})) {
    if (!spec || typeof spec !== "object") continue;
    const here = prefix ? `${prefix}.${name}` : name;
    if (typeof spec.source === "string") out[here] = spec.source;
    if (spec.children) flattenSources(spec.children, here, out);
  }
}

(async () => {
  const fresh = process.argv.includes("--fresh");
  let bundle;
  if (fresh) {
    const mod = await import(pathToFileURL(path.join(REPO, "bridge/compiler.mjs")).href);
    bundle = mod.compileSyncBundle();
    console.log("· biên dịch lại từ repo (--fresh)");
  } else {
    const file = path.join(REPO, "studio-sync.json");
    bundle = JSON.parse(read(file));
    console.log(`· đọc ${path.relative(REPO, file)} (bản đã commit — đúng thứ Studio tải về)`);
  }

  // 1. tác vụ dựng thành phố
  const actions = Array.isArray(bundle.actions) ? bundle.actions : [];
  const rebuild = actions.filter((a) => typeof a.code === "string" && a.code.includes("DistrictRegistry"));
  if (rebuild.length === 0) {
    bad(`Gói sync có ${actions.length} tác vụ nhưng KHÔNG có tác vụ dựng thành phố → Studio sẽ không đổi gì.`);
  } else {
    ok(`Có ${rebuild.length} tác vụ dựng thành phố (mới nhất: ${rebuild[rebuild.length - 1].id})`);
    const code = rebuild[rebuild.length - 1].code;
    for (const token of ["buildAll", "buildOne", "workspace", "LosSantos"]) {
      if (!code.includes(token)) bad(`Tác vụ dựng thành phố thiếu đoạn "${token}" — có thể đã lỗi thời.`);
    }
    if (!code.includes("World.BuildKit")) warnAll.push("Tác vụ chưa theo dõi World.BuildKit → sửa BuildKit sẽ không dựng lại.");
    if (!code.includes("World.BuildKit")) bad("Tác vụ dựng thành phố chưa có BuildKit trong FOUNDATION_KEYS.");
  }

  // 2. module công trình: có mặt + mã nguồn khớp đĩa
  const modulesDir = path.join(REPO, "src/shared/World/Modules");
  const moduleFiles = fs
    .readdirSync(modulesDir)
    .filter((f) => f.endsWith(".luau"))
    .sort();
  const sources = {};
  flattenSources(bundle.services, "", sources);

  let missing = 0;
  let stale = 0;
  for (const f of moduleFiles) {
    const name = f.replace(/\.luau$/, "");
    const key = `ReplicatedStorage.Shared.World.Modules.${name}`;
    const packed = sources[key];
    if (typeof packed !== "string") {
      bad(`Thiếu module ${name} trong gói sync`);
      missing++;
      continue;
    }
    if (packed !== read(path.join(modulesDir, f))) {
      bad(`Mã nguồn ${name} trong gói KHÁC trên đĩa (gói cũ / chưa publish)`);
      stale++;
    }
  }
  if (missing === 0 && stale === 0) ok(`${moduleFiles.length} module công trình có trong gói, mã nguồn khớp đĩa`);

  // 3. đếm file nguồn trong src/ so với gói
  const srcFiles = [];
  (function walk(dir) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p2 = path.join(dir, e.name);
      if (e.isDirectory()) walk(p2);
      else if (e.name.endsWith(".luau")) srcFiles.push(p2);
    }
  })(path.join(REPO, "src"));
  const packedCount = Object.keys(sources).length;
  if (packedCount < srcFiles.length) {
    bad(`Gói có ${packedCount} script nhưng src/ có ${srcFiles.length} file .luau → thiếu file`);
  } else {
    ok(`Gói có ${packedCount} script (src/ có ${srcFiles.length} file .luau)`);
  }

  // 4. version/hash để plugin nạp lại
  if (!bundle.hash) bad("Gói thiếu hash → plugin sẽ tưởng đã đồng bộ mới nhất và bỏ qua.");
  else ok(`hash ${String(bundle.hash).slice(0, 12)}… · version ${bundle.version} · ${(bundle.files || []).length} file Rojo`);

  // 5. liệt kê module công trình trong gói (nhìn là biết có C2/E1..E4 chưa)
  const inBundle = Object.keys(sources)
    .filter((k) => k.startsWith("ReplicatedStorage.Shared.World.Modules."))
    .map((k) => k.split(".").pop())
    .sort();
  console.log(`\n  Module công trình trong gói (${inBundle.length}):`);
  for (const n of inBundle) console.log(`    · ${n}`);

  console.log("");
  for (const w of warnAll) console.log(`  ⚠️  ${w}`);
  for (const m of okAll) console.log(`  ✅ ${m}`);
  for (const m of problems) console.log(`  ❌ ${m}`);
  console.log(problems.length === 0 ? "\n✅ Gói sync dùng được: Studio sẽ dựng lại thành phố sau khi nạp." : `\n❌ ${problems.length} lỗi trong gói sync.`);
  process.exit(problems.length === 0 ? 0 : 1);
})();
