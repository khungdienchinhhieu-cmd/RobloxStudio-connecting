import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import {
	REPO_ROOT,
	GITHUB_OWNER,
	GITHUB_REPO,
	GITHUB_BRANCH,
	loadExistingBundle,
	compileSyncBundle,
	buildGitHubCommandBarOneLiner,
} from "./compiler.mjs";

function getHeadSha() {
	try {
		return execFileSync("git", ["rev-parse", "HEAD"], { cwd: REPO_ROOT, encoding: "utf8" }).trim();
	} catch {
		return GITHUB_BRANCH;
	}
}

const PORT = Number(process.env.BRIDGE_PORT || 8080);
const HOST = "0.0.0.0";
const PLUGIN_FILE = path.join(REPO_ROOT, "plugin", "StudioLiveBridge.server.luau");

const HTML = `<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>GTA V Los Santos — Browser Simulator & Roblox Studio Live Sync</title>
<style>
  :root {
    --bg: #0b0e14;
    --card: #151924;
    --card-alt: #0f131c;
    --border: #262f45;
    --text: #eef2ff;
    --muted: #94a3b8;
    --primary: #3b82f6;
    --primary-hover: #2563eb;
    --green: #72cc72;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.5;
    padding: 16px;
  }
  .container { max-width: 1120px; margin: 0 auto; display: flex; flex-direction: column; gap: 16px; }
  .header {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 14px 18px;
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
  }
  .header h1 { font-size: 17px; font-weight: 800; letter-spacing: 0.2px; }
  .header p { font-size: 12.5px; color: var(--muted); margin-top: 2px; }
  .badge {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 6px 13px; border-radius: 999px; font-size: 12.5px; font-weight: 700;
    background: rgba(16, 185, 129, 0.15); color: #6ee7b7; border: 1px solid rgba(16, 185, 129, 0.4);
  }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: currentColor; }

  /* GTA V Interactive Viewport */
  .sim-wrap {
    position: relative;
    width: 100%;
    aspect-ratio: 16 / 9;
    min-height: 460px;
    background: #141a24;
    border-radius: 12px;
    overflow: hidden;
    border: 1px solid var(--border);
    box-shadow: 0 18px 40px rgba(0,0,0,0.45);
    user-select: none;
  }
  #worldCanvas { width: 100%; height: 100%; display: block; cursor: grab; }
  #worldCanvas:active { cursor: grabbing; }

  /* GTA V HUD Overlay */
  .hud-testbar {
    position: absolute; top: 14px; left: 18px;
    display: flex; gap: 6px; padding: 5px 8px;
    background: rgba(14, 18, 26, 0.84); border: 1px solid rgba(255,255,255,0.14);
    border-radius: 8px; backdrop-filter: blur(4px); z-index: 10;
  }
  .hud-btn {
    border: none; border-radius: 6px; padding: 5px 10px;
    font-size: 11.5px; font-weight: 700; color: #fff; cursor: pointer;
  }
  .hud-hint {
    position: absolute; top: 16px; left: 50%; transform: translateX(-50%);
    background: rgba(10,12,16,0.72); border: 1px solid rgba(255,255,255,0.12);
    border-radius: 999px; padding: 4px 14px; font-size: 11.5px; color: #cbd5e1; pointer-events: none;
  }
  .hud-topright {
    position: absolute; top: 14px; right: 22px; text-align: right; pointer-events: none;
    text-shadow: -1.5px -1.5px 0 #080a0e, 1.5px -1.5px 0 #080a0e, -1.5px 1.5px 0 #080a0e, 1.5px 1.5px 0 #080a0e;
  }
  .stars-row { font-size: 24px; letter-spacing: 3px; height: 28px; }
  .cash-txt { font-size: 29px; font-weight: 900; color: #72cc72; line-height: 1.1; }
  .delta-txt { font-size: 18px; font-weight: 800; min-height: 22px; }
  .clock-txt { font-size: 12px; font-weight: 700; color: #d7dee8; }

  .hud-feed {
    position: absolute; left: 20px; bottom: 206px; width: 258px;
    background: rgba(10, 12, 16, 0.84); border: 1px solid rgba(255,255,255,0.14);
    border-left: 4px solid #56ba56; border-radius: 4px;
    padding: 8px 11px; font-size: 12px; color: #f1f5f9; pointer-events: none;
  }
  .hud-radar-cluster {
    position: absolute; left: 20px; bottom: 18px; width: 258px;
    background: rgba(10, 12, 16, 0.92); padding: 2px; border-radius: 3px;
    box-shadow: 0 6px 20px rgba(0,0,0,0.6); pointer-events: none;
  }
  #radarCanvas { width: 254px; height: 164px; display: block; }
  .bars-strip {
    display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 3px;
    margin-top: 3px; height: 7px;
  }
  .bar-track { background: #1e293b; overflow: hidden; }
  .bar-fill { height: 100%; transition: width 0.12s linear; }

  .hud-bottomright {
    position: absolute; right: 22px; bottom: 18px; text-align: right; pointer-events: none;
    text-shadow: -1.5px -1.5px 0 #080a0e, 1.5px -1.5px 0 #080a0e, -1.5px 1.5px 0 #080a0e, 1.5px 1.5px 0 #080a0e;
  }
  .zone-txt { font-size: 15px; font-weight: 800; color: #f0c642; letter-spacing: 0.5px; }
  .street-txt { font-size: 22px; font-weight: 900; color: #f8fafc; }

  .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 16px 18px; }
  .card h2 { font-size: 15px; font-weight: 700; margin-bottom: 5px; }
  .sub { font-size: 12.5px; color: var(--muted); margin-bottom: 10px; }
  .code-box {
    background: var(--card-alt); border: 1px solid var(--border); border-radius: 8px;
    padding: 11px; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    font-size: 12px; color: #bfdbfe; overflow-x: auto; white-space: nowrap; margin-bottom: 10px; user-select: all;
  }
  .btn-row { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  button.action {
    background: var(--primary); color: #fff; border: none; border-radius: 8px;
    padding: 8px 14px; font-size: 13px; font-weight: 600; cursor: pointer;
  }
  button.action:hover { background: var(--primary-hover); }
  button.secondary { background: #242c40; color: #e2e8f0; border: 1px solid var(--border); }
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  @media (max-width: 760px) { .grid-2 { grid-template-columns: 1fr; } .hud-hint { display: none; } }
  .list { display: flex; flex-direction: column; gap: 6px; max-height: 190px; overflow-y: auto; }
  .list-item {
    background: var(--card-alt); border: 1px solid var(--border); border-radius: 7px;
    padding: 7px 10px; font-size: 12px; display: flex; justify-content: space-between; align-items: center;
  }
  .tag { font-size: 11px; padding: 2px 7px; border-radius: 4px; background: #252d42; color: #93c5fd; }
  .toast { font-size: 12px; color: #6ee7b7; font-weight: 600; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <div>
      <h1>🌴 GTA V Roblox (Los Santos) — Giai đoạn 1: UI + Nền Thành Phố</h1>
      <p id="repoMeta">Đang tải thông tin đồng bộ...</p>
    </div>
    <div class="badge"><span class="dot"></span><span id="verText">Live Sync v3 Sẵn Sàng</span></div>
  </div>

  <!-- BẢN MÔ PHỎNG 3D + GTA V HUD TRỰC QUAN NGAY TRÊN BROWSER -->
  <div class="sim-wrap" id="simWrap">
    <canvas id="worldCanvas"></canvas>

    <div class="hud-testbar" id="hudTestBar">
      <button class="hud-btn" style="background:#b9303a" onclick="simCmd('star')">+1★ Truy Nã</button>
      <button class="hud-btn" style="background:#343c4c" onclick="simCmd('clear')">Xoá ★</button>
      <button class="hud-btn" style="background:#248448" onclick="simCmd('cash')">+$500</button>
      <button class="hud-btn" style="background:#2563eb" onclick="simCmd('armor')">+Giáp</button>
      <button class="hud-btn" style="background:#4b5563" onclick="simCmd('hp')">Test Máu</button>
    </div>

    <div class="hud-hint">🖱️ Kéo chuột để xoay Camera 3D • ⌨️ WASD + Shift để đi dạo thử Radar & Tên Đường</div>

    <div class="hud-topright">
      <div class="stars-row" id="starsRow"></div>
      <div class="cash-txt" id="cashTxt">$5,000</div>
      <div class="delta-txt" id="deltaTxt"></div>
      <div class="clock-txt">LOS SANTOS • 16:48</div>
    </div>

    <div class="hud-feed" id="feedBox">
      <b>Chào mừng đến Los Santos!</b><br/>Giữ [Shift] chạy nhanh • [H] Ẩn/hiện thanh Test
    </div>

    <div class="hud-radar-cluster">
      <canvas id="radarCanvas" width="254" height="164"></canvas>
      <div class="bars-strip">
        <div class="bar-track" style="background:#1c341c"><div id="hpFill" class="bar-fill" style="width:100%;background:#56ba56"></div></div>
        <div class="bar-track" style="background:#162a3e"><div id="arFill" class="bar-fill" style="width:65%;background:#3b9be8"></div></div>
        <div class="bar-track" style="background:#3a3014"><div id="stFill" class="bar-fill" style="width:100%;background:#eec135"></div></div>
      </div>
    </div>

    <div class="hud-bottomright">
      <div class="zone-txt" id="zoneTxt">LEGION SQUARE</div>
      <div class="street-txt" id="streetTxt">Vespucci Blvd</div>
    </div>
  </div>

  <div class="card">
    <h2>🚀 Cầu nối Tự Động Roblox Studio (GitHub Atom + Raw CDN — Không giới hạn HTTP 403)</h2>
    <p class="sub">Nếu Studio của bạn đang mở bảng <b>Arena ↔ Studio Live Bridge v3</b>, bản Giai đoạn 1 này sẽ tự động cập nhật trong ~8 giây (hoặc bấm <b>🔄 Đồng bộ ngay</b>). Nếu mở file Studio mới, dán 1 dòng bên dưới vào Command Bar:</p>
    <div id="oneLinerBox" class="code-box">Đang tải...</div>
    <div class="btn-row">
      <button id="copyCmdBtn" class="action">📋 Sao chép lệnh Command Bar</button>
      <button id="copyPluginBtn" class="action secondary">📦 Sao chép mã Local Plugin</button>
      <span id="toast" class="toast"></span>
    </div>
  </div>

  <div class="grid-2">
    <div class="card">
      <h2>📁 Các Module GTA V (Rojo Architecture)</h2>
      <p class="sub">Tự động đồng bộ vào ReplicatedStorage, ServerScriptService, StarterPlayerScripts.</p>
      <div id="filesList" class="list"></div>
    </div>
    <div class="card">
      <h2>✨ Lịch sử Tác vụ Dựng Thế Giới (`Workspace.LosSantos`)</h2>
      <p class="sub">Hỗ trợ hoàn tác <code>Ctrl + Z</code> trực tiếp trong Studio.</p>
      <div id="actionsList" class="list"></div>
    </div>
  </div>
</div>

<script>
// === 1. DỮ LIỆU QUY HOẠCH ĐỐI XỨNG CHUẨN WORLDGRID.LUAU ===
const EW_ROADS = [
  { name: "Vinewood Blvd", coord: -224, width: 32, lanes: 2 },
  { name: "Olympic Fwy",   coord: -36,  width: 36, lanes: 4 },
  { name: "Vespucci Blvd", coord: 148,  width: 32, lanes: 2 },
];
const NS_ROADS = [
  { name: "Del Perro Fwy",   coord: -324, width: 32, lanes: 2 },
  { name: "San Andreas Ave", coord: -110, width: 36, lanes: 4 },
  { name: "Alta St",         coord: 110,  width: 36, lanes: 4 },
  { name: "Elgin Ave",       coord: 324,  width: 32, lanes: 2 },
];
const PLOTS = [
  { id: "D1", district: "ROCKFORD HILLS",    cx: -218, cz: -131, sx: 180, sz: 154 },
  { id: "D2", district: "PILLBOX HILL",      cx: 0,    cz: -131, sx: 184, sz: 154 },
  { id: "D3", district: "DOWNTOWN VINEWOOD", cx: 218,  cz: -131, sx: 180, sz: 154 },
  { id: "C1", district: "DEL PERRO",         cx: -218, cz: 57,   sx: 180, sz: 150 },
  { id: "C2", district: "LEGION SQUARE",     cx: 0,    cz: 57,   sx: 184, sz: 150, plaza: true },
  { id: "C3", district: "MISSION ROW",       cx: 218,  cz: 57,   sx: 180, sz: 150 },
];

const state = {
  px: 0, pz: 92, heading: 0,
  camYaw: -0.62, camPitch: 0.46, camDist: 235,
  cash: 5000, hp: 100, armor: 65, stamina: 100, wanted: 2,
};
const keys = {};
window.addEventListener("keydown", e => {
  keys[e.code] = true;
  if (e.code === "KeyH") {
    const tb = document.getElementById("hudTestBar");
    tb.style.display = tb.style.display === "none" ? "flex" : "none";
  }
});
window.addEventListener("keyup", e => { keys[e.code] = false; });

function showFeed(msg, color) {
  const fb = document.getElementById("feedBox");
  fb.style.borderLeftColor = color;
  fb.innerHTML = msg;
}
function fmtCash(n) { return "$" + n.toLocaleString("en-US"); }

window.simCmd = function(cmd) {
  if (cmd === "star") {
    state.wanted = Math.min(5, state.wanted + 1);
    showFeed("<b>LSPD ALERT:</b> Mức truy nã hiện tại là " + state.wanted + " Sao!", "#ef4444");
  } else if (cmd === "clear") {
    state.wanted = 0;
    showFeed("LSPD đã ngừng truy đuổi. Bạn đã thoát truy nã!", "#56ba56");
  } else if (cmd === "cash") {
    state.cash += 500;
    document.getElementById("cashTxt").textContent = fmtCash(state.cash);
    const dt = document.getElementById("deltaTxt");
    dt.style.color = "#dcfce7"; dt.textContent = "+$500";
    setTimeout(() => { dt.textContent = ""; }, 2000);
    showFeed("Maze Bank: Đã cộng <b>+$500</b> vào tiền mặt.", "#72cc72");
  } else if (cmd === "armor") {
    state.armor = state.armor >= 100 ? 0 : Math.min(100, state.armor + 50);
    showFeed("Ammu-Nation: Áo giáp chống đạn <b>" + state.armor + "%</b>.", "#3b9be8");
  } else if (cmd === "hp") {
    state.hp = state.hp <= 30 ? 100 : Math.max(20, state.hp - 30);
    showFeed(state.hp === 100 ? "Los Santos Medical: Đã hồi 100% máu!" : "Cảnh báo sát thương! Nhấn tiếp khi <30% để hồi đầy.", "#f59e0b");
  }
};

function getLocationInfo(x, z) {
  let district = "LOS SANTOS";
  if (z < -240) district = "VINEWOOD HILLS";
  else if (z >= 250) district = "PACIFIC OCEAN";
  else if (z >= 164) district = "VESPUCCI BEACH";
  else {
    for (const p of PLOTS) {
      if (Math.abs(x - p.cx) <= p.sx/2 + 18 && Math.abs(z - p.cz) <= p.sz/2 + 18) { district = p.district; break; }
    }
  }
  let best = "San Andreas State", bestD = 1e9, second = null;
  for (const r of EW_ROADS) {
    const d = Math.abs(z - r.coord);
    if (d < bestD) { if (bestD < 28) second = best; bestD = d; best = r.name; }
    else if (d < 28 && r.name !== best) second = r.name;
  }
  for (const r of NS_ROADS) {
    const d = Math.abs(x - r.coord);
    if (d < bestD) { if (bestD < 28) second = best; bestD = d; best = r.name; }
    else if (d < 28 && r.name !== best) second = r.name;
  }
  return [district, (second && bestD < 24) ? (best + " & " + second) : best];
}

// === 2. BỘ DỰNG 3D NHẸ MƯỢT TRÊN CANVAS ===
const wCanvas = document.getElementById("worldCanvas");
const wCtx = wCanvas.getContext("2d");
const rCanvas = document.getElementById("radarCanvas");
const rCtx = rCanvas.getContext("2d");

let dragging = false, lx = 0, ly = 0;
wCanvas.addEventListener("pointerdown", e => { dragging = true; lx = e.clientX; ly = e.clientY; wCanvas.setPointerCapture(e.pointerId); });
wCanvas.addEventListener("pointermove", e => {
  if (!dragging) return;
  state.camYaw -= (e.clientX - lx) * 0.007;
  state.camPitch = Math.max(0.18, Math.min(1.15, state.camPitch + (e.clientY - ly) * 0.006));
  lx = e.clientX; ly = e.clientY;
});
wCanvas.addEventListener("pointerup", () => { dragging = false; });
wCanvas.addEventListener("wheel", e => {
  e.preventDefault();
  state.camDist = Math.max(85, Math.min(460, state.camDist + e.deltaY * 0.22));
}, { passive: false });

const SLABS = [
  { cx:0, cy:0, cz:310, sx:720, sy:0.5, sz:110, col:"#14588e" },
  { cx:0, cy:0.1, cz:268, sx:720, sy:0.5, sz:36, col:"#248ab0" },
  { cx:0, cy:0.2, cz:238, sx:720, sy:0.5, sz:24, col:"#ba9e70" },
  { cx:0, cy:0.35, cz:206, sx:720, sy:0.6, sz:40, col:"#e0c692" },
  { cx:0, cy:0.6, cz:175, sx:720, sy:1.1, sz:22, col:"#c6bcab" },
  { cx:-350, cy:0.6, cz:-38, sx:20, sy:1.1, sz:404, col:"#b2b6bc" },
  { cx:350, cy:0.6, cz:-38, sx:20, sy:1.1, sz:404, col:"#b2b6bc" },
  { cx:0, cy:0.6, cz:-245, sx:720, sy:1.1, sz:10, col:"#b2b6bc" },
];
for (const r of EW_ROADS) SLABS.push({ cx:0, cy:0.5, cz:r.coord, sx:680, sy:0.2, sz:r.width, col:"#26292f" });
for (const r of NS_ROADS) SLABS.push({ cx:r.coord, cy:0.5, cz:-38, sx:r.width, sy:0.2, sz:404, col:"#26292f" });
for (const r of EW_ROADS) {
  for (let x = -330; x <= 330; x += 24) {
    if (NS_ROADS.some(n => Math.abs(x - n.coord) < 24)) continue;
    SLABS.push({ cx:x, cy:0.54, cz:r.coord, sx:14, sy:0.05, sz:1.3, col:"#eebc2e" });
  }
}
for (const r of NS_ROADS) {
  for (let z = -228; z <= 152; z += 24) {
    if (EW_ROADS.some(e => Math.abs(z - e.coord) < 24)) continue;
    SLABS.push({ cx:r.coord, cy:0.54, cz:z, sx:1.3, sy:0.05, sz:14, col:"#eebc2e" });
  }
}
for (const p of PLOTS) {
  SLABS.push({ cx:p.cx, cy:0.6, cz:p.cz, sx:p.sx, sy:1.15, sz:p.sz, col:"#b2b6bc" });
  if (p.plaza) {
    SLABS.push({ cx:p.cx, cy:1.2, cz:p.cz, sx:p.sx-18, sy:0.15, sz:p.sz-18, col:"#4e8648" });
    SLABS.push({ cx:p.cx, cy:1.25, cz:p.cz, sx:28, sy:0.15, sz:p.sz-18, col:"#cec8bc" });
    SLABS.push({ cx:p.cx, cy:1.25, cz:p.cz, sx:p.sx-18, sy:0.15, sz:24, col:"#cec8bc" });
    SLABS.push({ cx:p.cx, cy:1.28, cz:p.cz, sx:96, sy:0.15, sz:86, col:"#cec8bc" });
    SLABS.push({ cx:p.cx, cy:1.7, cz:p.cz-8, sx:44, sy:0.8, sz:32, col:"#40444c" });
    SLABS.push({ cx:p.cx, cy:2.15, cz:p.cz-8, sx:39, sy:0.15, sz:27, col:"#2a9ebc" });
    SLABS.push({ cx:p.cx, cy:7.5, cz:p.cz-8, sx:3.6, sy:9.5, sz:3.6, col:"#ce3030", tall:true });
    SLABS.push({ cx:p.cx, cy:13.2, cz:p.cz-8, sx:3.0, sy:3.0, sz:3.0, col:"#f5c838", tall:true });
  } else {
    SLABS.push({ cx:p.cx, cy:1.2, cz:p.cz, sx:p.sx-18, sy:0.15, sz:p.sz-18, col:"#8e949e" });
  }
}
const HILLS = [
  { cx:0, cy:7, cz:-280, sx:720, sy:14, sz:60, col:"#5c8044", tall:true },
  { cx:0, cy:16, cz:-316, sx:660, sy:22, sz:64, col:"#50723c", tall:true },
  { cx:0, cy:32, cz:-342, sx:260, sy:38, sz:36, col:"#446234", tall:true },
  { cx:-200, cy:24, cz:-338, sx:240, sy:28, sz:44, col:"#486838", tall:true },
  { cx:200, cy:24, cz:-338, sx:240, sy:28, sz:44, col:"#486838", tall:true },
];
SLABS.push(...HILLS);

function tick(now) {
  const dt = 0.016;
  const sprinting = keys["ShiftLeft"] || keys["ShiftRight"];
  const spd = (sprinting && state.stamina > 2) ? 62 : 34;
  let mx = 0, mz = 0;
  if (keys["KeyW"] || keys["ArrowUp"]) mz -= 1;
  if (keys["KeyS"] || keys["ArrowDown"]) mz += 1;
  if (keys["KeyA"] || keys["ArrowLeft"]) mx -= 1;
  if (keys["KeyD"] || keys["ArrowRight"]) mx += 1;
  if (mx !== 0 || mz !== 0) {
    const c = Math.cos(state.camYaw), s = Math.sin(state.camYaw);
    const wx = mx * c + mz * s, wz = -mx * s + mz * c;
    const len = Math.hypot(wx, wz);
    state.px = Math.max(-345, Math.min(345, state.px + (wx/len)*spd*dt));
    state.pz = Math.max(-245, Math.min(245, state.pz + (wz/len)*spd*dt));
    state.heading = Math.atan2(wx, -wz);
    if (sprinting) state.stamina = Math.max(0, state.stamina - 24 * dt);
  } else {
    state.stamina = Math.min(100, state.stamina + 18 * dt);
  }

  document.getElementById("hpFill").style.width = state.hp + "%";
  document.getElementById("hpFill").style.background = state.hp < 30 ? "#dc3838" : "#56ba56";
  document.getElementById("arFill").style.width = state.armor + "%";
  document.getElementById("stFill").style.width = state.stamina + "%";

  const pulse = Math.floor(now / 240) % 2 === 0;
  const sr = document.getElementById("starsRow");
  if (state.wanted > 0) {
    let html = "";
    for (let i = 1; i <= 5; i++) {
      const col = i <= state.wanted ? (pulse ? "#ffffff" : "#93c5fd") : "rgba(30,36,46,0.55)";
      html += '<span style="color:' + col + '">★</span>';
    }
    sr.innerHTML = html;
  } else sr.innerHTML = "";

  const [distName, stName] = getLocationInfo(state.px, state.pz);
  document.getElementById("zoneTxt").textContent = distName;
  document.getElementById("streetTxt").textContent = stName;

  // Render 3D Viewport
  const rect = wCanvas.getBoundingClientRect();
  if (wCanvas.width !== Math.floor(rect.width) || wCanvas.height !== Math.floor(rect.height)) {
    wCanvas.width = Math.floor(rect.width); wCanvas.height = Math.floor(rect.height);
  }
  const W = wCanvas.width, H = wCanvas.height;
  const sky = wCtx.createLinearGradient(0, 0, 0, H * 0.55);
  sky.addColorStop(0, "#3468b6"); sky.addColorStop(0.7, "#cfa28c"); sky.addColorStop(1, "#f6ba86");
  wCtx.fillStyle = sky; wCtx.fillRect(0, 0, W, H);
  wCtx.fillStyle = "#1c3f60"; wCtx.fillRect(0, H * 0.48, W, H * 0.52);

  const camX = state.px + Math.sin(state.camYaw) * Math.cos(state.camPitch) * state.camDist;
  const camY = 4 + Math.sin(state.camPitch) * state.camDist;
  const camZ = state.pz + Math.cos(state.camYaw) * Math.cos(state.camPitch) * state.camDist;
  const fx = state.px - camX, fy = 2 - camY, fz = state.pz - camZ;
  const fl = Math.hypot(fx, fy, fz);
  const fwd = [fx/fl, fy/fl, fz/fl];
  let rx = fwd[1]*0 - fwd[2]*1, ry = 0, rz = fwd[0]*1 - fwd[1]*0;
  // right = cross(fwd, up=(0,1,0)) = (-fwd.z, 0, fwd.x)
  rx = -fwd[2]; rz = fwd[0];
  const rl = Math.hypot(rx, rz); rx /= rl; rz /= rl;
  const ux = rz*fwd[1], uy = rz*fwd[0] - rx*fwd[2], uz = -rx*fwd[1];
  const focal = (H * 0.5) / Math.tan(Math.PI / 6);

  function proj3(x, y, z) {
    const dx = x - camX, dy = y - camY, dz = z - camZ;
    const cx = dx*rx + dz*rz;
    const cy = dx*ux + dy*uy + dz*uz;
    const cz = dx*fwd[0] + dy*fwd[1] + dz*fwd[2];
    if (cz < 4) return null;
    return [W*0.5 + (cx/cz)*focal, H*0.5 - (cy/cz)*focal, cz];
  }

  function drawTop(b) {
    const y = b.cy + b.sy*0.5;
    const pts = [
      proj3(b.cx - b.sx/2, y, b.cz - b.sz/2),
      proj3(b.cx + b.sx/2, y, b.cz - b.sz/2),
      proj3(b.cx + b.sx/2, y, b.cz + b.sz/2),
      proj3(b.cx - b.sx/2, y, b.cz + b.sz/2),
    ];
    if (pts.some(p => !p)) return;
    wCtx.fillStyle = b.col;
    wCtx.beginPath();
    wCtx.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < 4; i++) wCtx.lineTo(pts[i][0], pts[i][1]);
    wCtx.closePath(); wCtx.fill();
    if (b.tall) {
      const bpts = [
        proj3(b.cx - b.sx/2, 0, b.cz + b.sz/2),
        proj3(b.cx + b.sx/2, 0, b.cz + b.sz/2),
      ];
      if (!bpts[0] || !bpts[1]) return;
      wCtx.fillStyle = b.col;
      wCtx.beginPath();
      wCtx.moveTo(pts[3][0], pts[3][1]); wCtx.lineTo(pts[2][0], pts[2][1]);
      wCtx.lineTo(bpts[1][0], bpts[1][1]); wCtx.lineTo(bpts[0][0], bpts[0][1]);
      wCtx.closePath(); wCtx.fill();
    }
  }

  for (const s of SLABS.filter(x => !x.tall)) drawTop(s);
  const tallSorted = SLABS.filter(x => x.tall).sort((a,b) => Math.hypot(b.cx-camX, b.cz-camZ) - Math.hypot(a.cx-camX, a.cz-camZ));
  for (const s of tallSorted) drawTop(s);

  // Player marker in 3D
  const pp = proj3(state.px, 2.2, state.pz);
  if (pp) {
    wCtx.fillStyle = "#38bdf8"; wCtx.strokeStyle = "#fff"; wCtx.lineWidth = 2;
    wCtx.beginPath(); wCtx.arc(pp[0], pp[1], Math.max(4, 900/pp[2]), 0, Math.PI*2); wCtx.fill(); wCtx.stroke();
  }

  // Render Live Rotating GTA V Rectangular Minimap
  const rw = 254, rh = 164, S = 0.52;
  rCtx.fillStyle = "#1c2430"; rCtx.fillRect(0, 0, rw, rh);
  rCtx.save();
  rCtx.translate(rw/2, rh*0.56);
  rCtx.rotate(state.camYaw);
  rCtx.scale(S, S);
  rCtx.translate(-state.px, -state.pz);

  rCtx.fillStyle = "#2480c6"; rCtx.fillRect(-360, 246, 720, 120);
  rCtx.fillStyle = "#d6c08e"; rCtx.fillRect(-360, 174, 720, 72);
  rCtx.fillStyle = "#3a6036"; rCtx.fillRect(-360, -360, 720, 120);
  for (const p of PLOTS) {
    rCtx.fillStyle = p.plaza ? "#4e9254" : "#343c48";
    rCtx.fillRect(p.cx - p.sx/2, p.cz - p.sz/2, p.sx, p.sz);
  }
  rCtx.fillStyle = "#bab4a8";
  rCtx.fillRect(-14, 57-66, 28, 132); rCtx.fillRect(-83, 57-12, 166, 24); rCtx.fillRect(-48, 57-43, 96, 86);
  rCtx.fillStyle = "#2ea8ce"; rCtx.fillRect(-20, 49-14, 40, 28);
  rCtx.fillStyle = "#ccd6e2";
  for (const r of EW_ROADS) rCtx.fillRect(-340, r.coord - r.width/2, 680, r.width);
  for (const r of NS_ROADS) rCtx.fillRect(r.coord - r.width/2, -240, r.width, 404);
  rCtx.fillStyle = "#facc15"; rCtx.beginPath(); rCtx.arc(0, 49, 8, 0, Math.PI*2); rCtx.fill();
  rCtx.restore();

  if (state.wanted > 0) {
    rCtx.fillStyle = pulse ? "rgba(239,68,68,0.16)" : "rgba(59,130,246,0.16)";
    rCtx.fillRect(0, 0, rw, rh);
  }

  // Player cursor arrow & North 'N' badge
  rCtx.save();
  rCtx.translate(rw/2, rh*0.56);
  rCtx.rotate(state.heading + state.camYaw);
  rCtx.fillStyle = "#fff"; rCtx.strokeStyle = "#0a0c10"; rCtx.lineWidth = 2;
  rCtx.beginPath(); rCtx.moveTo(0, -8); rCtx.lineTo(6, 6); rCtx.lineTo(0, 3); rCtx.lineTo(-6, 6); rCtx.closePath();
  rCtx.fill(); rCtx.stroke();
  rCtx.restore();

  const na = state.camYaw - Math.PI/2;
  const nx = Math.max(12, Math.min(rw-12, rw/2 + Math.cos(na)*112));
  const ny = Math.max(12, Math.min(rh-12, rh/2 + Math.sin(na)*74));
  rCtx.fillStyle = "#0a0c10"; rCtx.beginPath(); rCtx.arc(nx, ny, 9, 0, Math.PI*2); rCtx.fill();
  rCtx.fillStyle = "#fff"; rCtx.font = "bold 10px sans-serif"; rCtx.textAlign = "center"; rCtx.textBaseline = "middle";
  rCtx.fillText("N", nx, ny);

  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);

// === 3. PANEL CẦU NỐI ROBLOX STUDIO ===
let oneLiner = "";
function showToast(t) {
  const el = document.getElementById("toast");
  el.textContent = t;
  setTimeout(() => { if (el.textContent === t) el.textContent = ""; }, 3000);
}
async function copySafe(text, name) {
  try { await navigator.clipboard.writeText(text); showToast("✓ Đã sao chép " + name + "!"); return; } catch (_) {}
  const ta = document.createElement("textarea");
  ta.value = text; ta.style.position = "fixed"; ta.style.opacity = "0";
  document.body.appendChild(ta); ta.select();
  document.execCommand("copy"); document.body.removeChild(ta);
  showToast("✓ Đã sao chép " + name + "!");
}
document.getElementById("copyCmdBtn").onclick = () => copySafe(oneLiner, "lệnh Command Bar");
document.getElementById("copyPluginBtn").onclick = async () => {
  const r = await fetch("/api/plugin-source");
  copySafe(await r.text(), "mã Local Plugin");
};
async function load() {
  const r = await fetch("/api/state");
  const d = await r.json();
  oneLiner = d.oneLiner;
  document.getElementById("oneLinerBox").textContent = d.oneLiner;
  document.getElementById("repoMeta").textContent = d.repo + " • Nhánh: " + d.branch + " • Hash: " + d.bundle.hash;
  document.getElementById("verText").textContent = "Sync v" + d.bundle.version + " (" + d.bundle.files.length + " module)";
  document.getElementById("filesList").innerHTML = d.bundle.files.map(f =>
    '<div class="list-item"><span>' + f.repoPath + '</span><span class="tag">' + f.className + '</span></div>'
  ).join("");
  const acts = d.bundle.actions || [];
  document.getElementById("actionsList").innerHTML = acts.length
    ? acts.slice().reverse().map(a => '<div class="list-item"><span>' + a.description + '</span><span class="tag">' + a.id + '</span></div>').join("")
    : '<div class="list-item"><span>Sẵn sàng đồng bộ sang Roblox Studio</span><span class="tag">Ready</span></div>';
}
load();
setInterval(load, 3000);
</script>
</body>
</html>`;

const server = http.createServer((req, res) => {
	const url = new URL(req.url || "/", "http://localhost");
	if (url.pathname === "/") {
		res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
		res.end(HTML);
		return;
	}
	if (url.pathname === "/api/state") {
		const bundle = fs.existsSync(path.join(REPO_ROOT, "studio-sync.json"))
			? loadExistingBundle()
			: compileSyncBundle();
		res.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
		res.end(
			JSON.stringify({
				repo: `${GITHUB_OWNER}/${GITHUB_REPO}`,
				branch: GITHUB_BRANCH,
				oneLiner: buildGitHubCommandBarOneLiner(getHeadSha()),
				bundle,
			})
		);
		return;
	}
	if (url.pathname === "/api/plugin-source") {
		res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" });
		res.end(fs.readFileSync(PLUGIN_FILE, "utf8"));
		return;
	}
	res.writeHead(404);
	res.end("Not found");
});

server.listen(PORT, HOST, () => {
	console.log(`[Arena GTA V Simulator & Studio Live Sync] Listening on http://${HOST}:${PORT}`);
});
