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
import { computeRadarSnapshot, triggerGitFetchAsync } from "./qa-radar.mjs";

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

  /* GTA V [H] Interaction Menu Overlay */
  .hud-h-hint {
    position: absolute; top: 14px; left: 18px;
    background: rgba(10, 12, 16, 0.62); border: 1px solid rgba(255,255,255,0.14);
    color: #d7e0ec; border-radius: 4px; padding: 5px 11px;
    font-size: 11.5px; font-weight: 700; cursor: pointer; z-index: 10;
  }
  .hud-menu {
    position: absolute; top: 14px; left: 18px; width: 258px;
    background: rgba(10, 13, 18, 0.92); border: 2px solid #000;
    display: none; flex-direction: column; z-index: 12;
    box-shadow: 0 12px 30px rgba(0,0,0,0.65);
  }
  .hud-menu-head {
    background: #184a94; padding: 7px 11px;
    display: flex; justify-content: space-between; align-items: center;
  }
  .hud-menu-head b { font-size: 14px; letter-spacing: 0.4px; display: block; }
  .hud-menu-head span { font-size: 10px; color: #bfdbfe; font-weight: 700; }
  .hud-menu-close {
    background: rgba(12, 24, 48, 0.78); color: #e2e8f0; border: none;
    border-radius: 4px; padding: 4px 8px; font-size: 10px; font-weight: 700; cursor: pointer;
  }
  .hud-menu-body { padding: 6px; display: flex; flex-direction: column; gap: 4px; }
  .hud-row-btn {
    background: #161b24; color: #f1f5f9; border: none; border-left: 3px solid #fff;
    padding: 7px 10px; font-size: 12px; font-weight: 700; cursor: pointer;
    display: flex; justify-content: space-between; align-items: center; text-align: left;
  }
  .hud-row-btn:hover { background: #232c3d; }
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
  .speedo-box { margin-bottom: 6px; display: none; }
  .car-tag { font-size: 11.5px; font-weight: 800; color: #38bdf8; letter-spacing: 0.6px; }
  .mph-txt { font-size: 26px; font-weight: 900; color: #f8fafc; line-height: 1.05; }

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

  /* TRẠM RADA GIÁM SÁT & BÁO CHUÔNG NGHIỆM THU ĐA-AGENT */
  .radar-card {
    background: linear-gradient(180deg, #161d2e 0%, #111623 100%);
    border: 1px solid #2e3b59;
    border-radius: 12px;
    padding: 14px 16px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .radar-card.has-pending {
    border-color: #a855f7;
    box-shadow: 0 0 0 2px rgba(168, 85, 247, 0.28), 0 12px 30px rgba(168, 85, 247, 0.22);
  }
  .radar-top {
    display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 10px;
  }
  .radar-title { font-size: 15px; font-weight: 800; display: flex; align-items: center; gap: 8px; }
  .radar-pulse {
    width: 9px; height: 9px; border-radius: 50%; background: #38bdf8;
    box-shadow: 0 0 10px #38bdf8; animation: rpulse 1.6s infinite;
  }
  @keyframes rpulse { 0%,100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.35); opacity: 0.55; } }
  .qa-banner {
    display: none;
    background: linear-gradient(90deg, rgba(147,51,234,0.28), rgba(16,185,129,0.24));
    border: 1px solid #c084fc;
    border-radius: 10px;
    padding: 11px 14px;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
  }
  .qa-banner.active { display: flex; }
  .qa-banner-txt b { color: #f3e8ff; font-size: 14px; display: block; }
  .qa-banner-txt span { color: #d8b4fe; font-size: 12.5px; }
  .qa-copy-btn {
    background: #10b981; color: #052e16; border: none; border-radius: 8px;
    padding: 8px 14px; font-size: 12.5px; font-weight: 800; cursor: pointer;
  }
  .qa-copy-btn:hover { background: #34d399; }
  .radar-grid {
    display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px;
  }
  @media (max-width: 920px) { .radar-grid { grid-template-columns: repeat(2, 1fr); } }
  @media (max-width: 560px) { .radar-grid { grid-template-columns: 1fr; } }
  .plot-tile {
    background: #0d121d; border: 1px solid #232d45; border-radius: 8px; padding: 9px 10px;
    display: flex; flex-direction: column; gap: 4px; font-size: 11.5px;
  }
  .plot-tile.IN_PROGRESS { border-color: #f59e0b; background: rgba(245, 158, 11, 0.08); }
  .plot-tile.NEEDS_QA_SUBMITTED, .plot-tile.NEEDS_QA_MODULE_PUSHED {
    border-color: #c084fc; background: rgba(168, 85, 247, 0.16);
  }
  .plot-tile.INTEGRATED { border-color: rgba(16,185,129,0.45); background: rgba(16,185,129,0.07); }
  .plot-head { display: flex; justify-content: space-between; font-weight: 800; color: #f1f5f9; }
  .plot-sub { color: #94a3b8; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .plot-status { font-weight: 700; font-size: 11px; margin-top: 2px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <div>
      <h1>🏎️ GTA V Roblox (Los Santos) — Trạm Điều Phối Đa-Agent &amp; Live Sync v3.1</h1>
      <p id="repoMeta">Đang tải thông tin đồng bộ...</p>
    </div>
    <div class="badge"><span class="dot"></span><span id="verText">Live Sync v3.1 Sẵn Sàng</span></div>
  </div>

  <!-- TRẠM RADA TỰ ĐỘNG BÁO CHUÔNG KHI AGENT PHỤ LÀM XONG -->
  <div class="radar-card" id="radarCard">
    <div class="radar-top">
      <div class="radar-title">
        <span class="radar-pulse"></span>
        <span>📡 Rada Giám Sát Agent Phụ &amp; Báo Nghiệm Thu Tự Động</span>
        <span id="radarSummaryTag" class="tag">Đang quét GitHub mỗi 7 giây...</span>
      </div>
      <div class="btn-row">
        <button id="soundToggleBtn" class="action secondary" style="padding:5px 11px;font-size:12px">🔔 Chuông báo: BẬT</button>
        <button id="refreshRadarBtn" class="action secondary" style="padding:5px 11px;font-size:12px">🔄 Quét ngay</button>
      </div>
    </div>

    <div class="qa-banner" id="qaBanner">
      <div class="qa-banner-txt">
        <b id="qaBannerTitle">🔔 PHÁT HIỆN CÔNG TRÌNH ĐÃ XONG — CẦN NGHIỆM THU!</b>
        <span id="qaBannerDetail">Nhắn câu "Nghiệm thu đi" vào khung chat của Agent Chính để kiểm định 3D &amp; đẩy lên Studio!</span>
      </div>
      <button class="qa-copy-btn" id="copyQaCmdBtn">📋 Copy "Nghiệm thu đi"</button>
    </div>

    <div class="radar-grid" id="radarGrid"></div>
    <div id="workerFeed" style="font-size:11.5px;color:#94a3b8"></div>
  </div>

  <!-- BẢN MÔ PHỎNG 3D + GTA V HUD TRỰC QUAN NGAY TRÊN BROWSER -->
  <div class="sim-wrap" id="simWrap">
    <canvas id="worldCanvas"></canvas>

    <button class="hud-h-hint" id="hudOpenHint" onclick="toggleDevMenu()">[H] Mở Menu Test</button>

    <div class="hud-menu" id="hudTestBar">
      <div class="hud-menu-head">
        <div><b>LOS SANTOS</b><span>MENU KIỂM THỬ HỆ THỐNG</span></div>
        <button class="hud-menu-close" onclick="toggleDevMenu()">[H] Đóng</button>
      </div>
      <div class="hud-menu-body">
        <button class="hud-row-btn" style="border-left-color:#38bdf8" onclick="simCmd('car')"><span>▶ &nbsp;Gọi Siêu Xe Trước Mặt</span><span style="color:#38bdf8;font-size:10px">CAR</span></button>
        <button class="hud-row-btn" style="border-left-color:#ef4444" onclick="simCmd('star')"><span>★ &nbsp;Tăng +1 Sao Truy Nã</span><span style="color:#ef4444;font-size:10px">LSPD</span></button>
        <button class="hud-row-btn" style="border-left-color:#94a3b8" onclick="simCmd('clear')"><span>☆ &nbsp;Xoá Toàn Bộ Truy Nã</span><span style="color:#94a3b8;font-size:10px">0 ★</span></button>
        <button class="hud-row-btn" style="border-left-color:#72cc72" onclick="simCmd('cash')"><span>$ &nbsp;Nhận +$500 Tiền Mặt</span><span style="color:#72cc72;font-size:10px">+$500</span></button>
        <button class="hud-row-btn" style="border-left-color:#3b9be8" onclick="simCmd('armor')"><span>◆ &nbsp;Nạp / Đổi Áo Giáp</span><span style="color:#3b9be8;font-size:10px">ARMOR</span></button>
        <button class="hud-row-btn" style="border-left-color:#f59e0b" onclick="simCmd('hp')"><span>✚ &nbsp;Thử Sát Thương / Hồi Máu</span><span style="color:#f59e0b;font-size:10px">HP</span></button>
      </div>
    </div>

    <div class="hud-hint">⌨️ WASD đi/lái • [F] Lên/Xuống xe • [Space] Bắn gạch &amp; xe (máu ẩn tự vỡ!) • [H] Menu</div>

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
      <div class="speedo-box" id="speedoBox">
        <div class="car-tag" id="carTag">BANSHEE GT</div>
        <div class="mph-txt" id="mphTxt">0 MPH</div>
      </div>
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
      <h2>✨ Lịch sử Tác vụ Dựng Thế Giới (<code>Workspace.LosSantos</code>)</h2>
      <p class="sub">Hỗ trợ hoàn tác <code>Ctrl + Z</code> trực tiếp trong Studio.</p>
      <div id="actionsList" class="list"></div>
    </div>
  </div>
</div>

<script>
// === 1. DỮ LIỆU QUY HOẠCH ĐỐI XỨNG CHUẨN WORLDGRID.LUAU ===
// Sync v22 — tỉ lệ 1:1 ngoài đời: 1 m = 3,33 stud
const STUDS_PER_M = 3.33;
const SIDEWALK_W = 14; // 4,2 m
const EW_ROADS = [
  { name: "Vinewood Blvd", coord: -224, width: 40, lanes: 2 },
  { name: "Olympic Fwy",   coord: -36,  width: 48, lanes: 4 },
  { name: "Vespucci Blvd", coord: 148,  width: 40, lanes: 2 },
];
const NS_ROADS = [
  { name: "Pacific Coast Hwy", coord: -556, width: 40, lanes: 2 },
  { name: "Del Perro Fwy",     coord: -338, width: 40, lanes: 2 },
  { name: "San Andreas Ave",   coord: -110, width: 48, lanes: 4 },
  { name: "Alta St",           coord: 110,  width: 48, lanes: 4 },
  { name: "Elgin Ave",         coord: 338,  width: 40, lanes: 2 },
  { name: "La Mesa Ave",       coord: 556,  width: 40, lanes: 2 },
];
const PLOTS = [
  { id: "E1", district: "PACIFIC BLUFFS",    cx: -447, cz: -132, sx: 178, sz: 144 },
  { id: "D1", district: "ROCKFORD HILLS",    cx: -226, cz: -132, sx: 184, sz: 144 },
  { id: "D2", district: "PILLBOX HILL",      cx: 0,    cz: -132, sx: 172, sz: 144 },
  { id: "D3", district: "DOWNTOWN VINEWOOD", cx: 226,  cz: -132, sx: 184, sz: 144 },
  { id: "E2", district: "LA MESA",           cx: 447,  cz: -132, sx: 178, sz: 144 },
  { id: "E3", district: "LITTLE SEOUL",      cx: -447, cz: 58,   sx: 178, sz: 140 },
  { id: "C1", district: "DEL PERRO",         cx: -226, cz: 58,   sx: 184, sz: 140 },
  { id: "C2", district: "LEGION SQUARE",     cx: 0,    cz: 58,   sx: 172, sz: 140, plaza: true },
  { id: "C3", district: "MISSION ROW",       cx: 226,  cz: 58,   sx: 184, sz: 140 },
  { id: "E4", district: "RICHMAN GLEN",      cx: 447,  cz: 58,   sx: 178, sz: 140 },
];

const state = {
  px: -12, pz: 118, heading: 0,
  camYaw: -0.45, camPitch: 0.38, camDist: 210,
  cash: 5000, hp: 100, armor: 65, stamina: 100, wanted: 0,
  drivingCar: null, tracerTimer: 0, tracerEnd: null, hitShatter: false,
};
const CARS = [
  { name: "BANSHEE GT",   cx: -24, cz: 139, yaw: -Math.PI/2, spd: 0, col: "#d21e26", hoodHp: 140, maxHoodHp: 140, glassHp: 55 },
  { name: "GAUNTLET GTX", cx: -99, cz: 78,  yaw: 0,          spd: 0, col: "#1a1c22", hoodHp: 150, maxHoodHp: 150, glassHp: 55 },
  { name: "BANSHEE GT",   cx: -36, cz: -25, yaw: Math.PI/2,  spd: 0, col: "#1848aa", hoodHp: 140, maxHoodHp: 140, glassHp: 55 },
  { name: "BANSHEE GT",   cx: 42,  cz: 139, yaw: Math.PI/2,  spd: 0, col: "#ee7c18", hoodHp: 140, maxHoodHp: 140, glassHp: 55 },
];
const PROPS = [];
// Các bồn gạch Sandstone & cọc chắn quảng trường có máu ẩn (hp) — xe đụng hoặc bắn hết máu là tự vỡ tung!
for (let x = -72; x <= 72; x += 9) {
  if (Math.abs(x) < 16) continue;
  PROPS.push({ cx: x, cy: 1.9, cz: 118, sx: 7.8, sy: 1.5, sz: 2.2, col: "#cfc5b2", r:207, g:197, b:178, hp: 120, maxHp: 120 });
}
for (let x = -14; x <= 14; x += 5.5) {
  PROPS.push({ cx: x, cy: 2.1, cz: 120, sx: 1.3, sy: 2.4, sz: 1.3, col: "#262a32", r:38, g:42, b:50, hp: 85, maxHp: 85 });
}
const DEBRIS = [];
function spawnBurst(cx, cy, cz, col, n) {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2, sp = 14 + Math.random() * 26;
    DEBRIS.push({
      cx, cy: cy + 0.5, cz,
      vx: Math.cos(a)*sp, vy: 14 + Math.random()*18, vz: Math.sin(a)*sp,
      sx: 1.5, sy: 1.1, sz: 1.5, col, ttl: 2.6,
    });
  }
}
function damageProp(p, dmg) {
  if (p.hp <= 0) return false;
  p.hp = Math.max(0, p.hp - dmg);
  const k = 1 - 0.35 * (1 - p.hp / p.maxHp);
  p.col = "rgb(" + Math.round(p.r*k) + "," + Math.round(p.g*k) + "," + Math.round(p.b*k) + ")";
  if (p.hp <= 0) {
    spawnBurst(p.cx, p.cy, p.cz, p.col, 5);
    return true;
  }
  return false;
}
function fireGun() {
  const dirX = Math.sin(state.heading), dirZ = -Math.cos(state.heading);
  let bestT = 85, hitObj = null, hitKind = "";
  for (const p of PROPS) {
    if (p.hp <= 0) continue;
    const dx = p.cx - state.px, dz = p.cz - state.pz;
    const proj = dx*dirX + dz*dirZ;
    const perp = Math.abs(dx*dirZ - dz*dirX);
    if (proj > 1 && proj < bestT && perp < Math.max(p.sx, p.sz)*0.65 + 1.8) {
      bestT = proj; hitObj = p; hitKind = "prop";
    }
  }
  for (const c of CARS) {
    if (c === state.drivingCar) continue;
    const dx = c.cx - state.px, dz = c.cz - state.pz;
    const proj = dx*dirX + dz*dirZ;
    const perp = Math.abs(dx*dirZ - dz*dirX);
    if (proj > 1 && proj < bestT && perp < 5.5) {
      bestT = proj; hitObj = c; hitKind = "car";
    }
  }
  state.tracerEnd = [state.px + dirX * bestT, state.pz + dirZ * bestT];
  state.tracerTimer = 0.14;
  state.hitShatter = false;
  if (hitKind === "prop") {
    state.hitShatter = damageProp(hitObj, 42);
    if (state.hitShatter) showFeed("💥 Khối gạch hết máu ẩn -> <b>TỰ ĐỘNG VỠ VỤN!</b>", "#f87171");
  } else if (hitKind === "car") {
    if (hitObj.glassHp > 0) {
      hitObj.glassHp = Math.max(0, hitObj.glassHp - 35);
      if (hitObj.glassHp === 0) { spawnBurst(hitObj.cx, 2.8, hitObj.cz, "#7dd3fc", 6); state.hitShatter = true; showFeed("💥 Kính chắn gió xe hết máu ẩn -> <b>VỠ TAN!</b>", "#38bdf8"); }
    } else if (hitObj.hoodHp > 0) {
      hitObj.hoodHp = Math.max(0, hitObj.hoodHp - 48);
      if (hitObj.hoodHp === 0) { spawnBurst(hitObj.cx, 2.6, hitObj.cz, hitObj.col, 4); state.hitShatter = true; showFeed("💥 Nắp Capo hết máu ẩn -> <b>BUNG RỜI LỘ MÁY V8!</b>", "#fb923c"); }
    }
  }
}
window.toggleDevMenu = function() {
  const tb = document.getElementById("hudTestBar");
  const hint = document.getElementById("hudOpenHint");
  const opening = tb.style.display !== "flex";
  tb.style.display = opening ? "flex" : "none";
  hint.style.display = opening ? "none" : "block";
};
const keys = {};
window.addEventListener("keydown", e => {
  keys[e.code] = true;
  if (e.code === "KeyH") window.toggleDevMenu();
  if (e.code === "Space") { e.preventDefault(); fireGun(); }
  if (e.code === "KeyF") {
    if (state.drivingCar) {
      const exited = state.drivingCar;
      exited.doorTimer = 0.72;
      state.px = exited.cx - Math.cos(exited.yaw) * 7.5;
      state.pz = exited.cz - Math.sin(exited.yaw) * 7.5;
      exited.spd = 0; state.drivingCar = null;
      showFeed("🚪 Mở cửa bước xuống xe! Nhấn <b>[Space]</b> bắn thử gạch &amp; xe.", "#94a3b8");
    } else {
      let near = null, bd = 24;
      for (const c of CARS) {
        const d = Math.hypot(c.cx - state.px, c.cz - state.pz);
        if (d < bd) { bd = d; near = c; }
      }
      if (near) {
        near.doorTimer = 0.75;
        setTimeout(() => { state.drivingCar = near; }, 220);
        showFeed("🚪 Mở cửa 64° lên siêu xe <b>" + near.name + "</b>! Lái WASD đâm thử tường gạch!", "#38bdf8");
      } else {
        showFeed("Lại gần xe hơn hoặc bấm <b>[H] -> Gọi Siêu Xe</b>!", "#f59e0b");
      }
    }
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
  if (cmd === "car") {
    const nx = state.px + Math.sin(state.heading) * 14;
    const nz = state.pz - Math.cos(state.heading) * 14;
    const nc = { name: "BANSHEE GT", cx: nx, cz: nz, yaw: state.heading, spd: 0, col: "#dc2626", hoodHp: 140, maxHoodHp: 140, glassHp: 55 };
    CARS.push(nc);
    showFeed("Legendary Motorsport: Đã giao <b>Banshee GT</b> ngay trước mặt! Nhấn <b>[F]</b> lên xe.", "#38bdf8");
  } else if (cmd === "star") {
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
  if (z < -244) district = "VINEWOOD HILLS";
  else if (z >= 254) district = "PACIFIC OCEAN";
  else if (z >= 168) district = "VESPUCCI BEACH";
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
  state.camDist = Math.max(85, Math.min(620, state.camDist + e.deltaY * 0.22));
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
for (const [a, b] of [[-296,-138],[-82,82],[138,296]]) {
  for (let x = a + 7; x <= b - 7; x += 14) {
    SLABS.push({ cx:x, cy:1.3, cz:-36, sx:13.2, sy:1.8, sz:1.8, col:"#a8acb2", tall:true });
  }
}
for (const jx of [-150, 150]) {
  for (let s = 1; s <= 8; s++) {
    SLABS.push({ cx:jx, cy:0.5, cz:232 + s*7.2, sx:8.5 - s*0.4, sy:1.8, sz:6.5, col:"#606268", tall:true });
  }
}
for (const p of PLOTS) {
  SLABS.push({ cx:p.cx, cy:0.6, cz:p.cz, sx:p.sx, sy:1.15, sz:p.sz, col:"#b6b9be" });
  if (p.plaza) {
    SLABS.push({ cx:p.cx, cy:1.2, cz:p.cz, sx:p.sx-18, sy:0.15, sz:p.sz-18, col:"#488444" });
    SLABS.push({ cx:p.cx, cy:1.25, cz:p.cz, sx:30, sy:0.15, sz:p.sz-18, col:"#d4ccbe" });
    SLABS.push({ cx:p.cx, cy:1.25, cz:p.cz, sx:p.sx-18, sy:0.15, sz:26, col:"#d4ccbe" });
    SLABS.push({ cx:p.cx, cy:1.9, cz:p.cz-4, sx:88, sy:1.2, sz:74, col:"#c2b9aa", tall:true });
    SLABS.push({ cx:p.cx, cy:2.8, cz:p.cz-6, sx:44, sy:1.1, sz:32, col:"#363a42", tall:true });
    SLABS.push({ cx:p.cx, cy:3.1, cz:p.cz-6, sx:39, sy:0.2, sz:27, col:"#26a4c4", tall:true });
    SLABS.push({ cx:p.cx, cy:8.5, cz:p.cz-6, sx:3.4, sy:10.5, sz:3.2, col:"#d22c2c", tall:true });
    SLABS.push({ cx:p.cx, cy:15.2, cz:p.cz-6, sx:2.8, sy:2.8, sz:2.8, col:"#f0be2c", tall:true });
  } else {
    SLABS.push({ cx:p.cx, cy:1.2, cz:p.cz, sx:p.sx-18, sy:0.15, sz:p.sz-18, col:"#8a909a" });
    SLABS.push({ cx:p.cx, cy:1.8, cz:p.cz-(p.cz<0?1:-1)*(p.sz/2-10), sx:p.sx-18, sy:1.1, sz:1.5, col:"#a4a8ae", tall:true });
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
  const spBox = document.getElementById("speedoBox");
  if (state.drivingCar) {
    const car = state.drivingCar;
    let thr = 0, str = 0;
    if (keys["KeyW"] || keys["ArrowUp"]) thr += 1;
    if (keys["KeyS"] || keys["ArrowDown"]) thr -= 1;
    if (keys["KeyA"] || keys["ArrowLeft"]) str -= 1;
    if (keys["KeyD"] || keys["ArrowRight"]) str += 1;
    if (thr !== 0) car.spd = Math.max(-45, Math.min(115, car.spd + thr * 92 * dt));
    else car.spd *= 0.96;
    if (Math.abs(car.spd) > 2) car.yaw += str * (car.spd >= 0 ? 1 : -1) * 2.1 * dt;
    car.cx = Math.max(-345, Math.min(345, car.cx + Math.sin(car.yaw) * car.spd * dt));
    car.cz = Math.max(-245, Math.min(245, car.cz - Math.cos(car.yaw) * car.spd * dt));
    state.px = car.cx; state.pz = car.cz; state.heading = car.yaw;

    // Va chạm xe trừ máu ẩn PartHealth của tường gạch & nắp capo!
    if (Math.abs(car.spd) > 16) {
      for (const p of PROPS) {
        if (p.hp <= 0) continue;
        if (Math.abs(car.cx - p.cx) < p.sx*0.5 + 4.2 && Math.abs(car.cz - p.cz) < p.sz*0.5 + 4.2) {
          const dmg = Math.abs(car.spd) * 1.45;
          const broke = damageProp(p, dmg);
          if (car.hoodHp > 0) {
            car.hoodHp = Math.max(0, car.hoodHp - dmg * 0.45);
            if (car.hoodHp === 0) spawnBurst(car.cx, 2.5, car.cz, car.col, 4);
          }
          car.spd *= 0.68;
          if (broke) showFeed("💥 Xe đụng vỡ tung khối gạch quảng trường!", "#fb923c");
        }
      }
    }
    spBox.style.display = "block";
    document.getElementById("carTag").textContent = car.name;
    document.getElementById("mphTxt").textContent = Math.round(Math.abs(car.spd) * 0.82) + " MPH";
  } else {
    spBox.style.display = "none";
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
  }
  if (state.tracerTimer > 0) state.tracerTimer = Math.max(0, state.tracerTimer - dt);
  for (let i = DEBRIS.length - 1; i >= 0; i--) {
    const d = DEBRIS[i];
    d.ttl -= dt; d.vy -= 48 * dt;
    d.cx += d.vx * dt; d.cy = Math.max(0.6, d.cy + d.vy * dt); d.cz += d.vz * dt;
    if (d.cy <= 0.65) { d.vy *= -0.35; d.vx *= 0.7; d.vz *= 0.7; }
    if (d.ttl <= 0) DEBRIS.splice(i, 1);
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
  const dynBlocks = [
    ...SLABS.filter(x => x.tall),
    ...PROPS.filter(p => p.hp > 0).map(p => ({ ...p, tall: true })),
    ...DEBRIS.map(d => ({ ...d, tall: true })),
  ];
  for (const c of CARS) {
    if (c.doorTimer && c.doorTimer > 0) c.doorTimer = Math.max(0, c.doorTimer - dt);
    const sy = Math.sin(c.yaw), cy = Math.cos(c.yaw);
    // Thân xe cao thoáng + Khoang lái hiển thị đồng hồ cyan bên trong + Cánh cửa mở xoay khi bấm [F]!
    dynBlocks.push({ cx: c.cx, cy: 1.9, cz: c.cz, sx: 8.8, sy: 2.3, sz: 8.8, col: c.col, tall: true });
    dynBlocks.push({ cx: c.cx + sy*1.2, cy: 3.3, cz: c.cz - cy*1.2, sx: 3.4, sy: 0.7, sz: 3.4, col: "#38bdf8", tall: true });
    if (c.hoodHp > 0) {
      dynBlocks.push({ cx: c.cx + sy*3.4, cy: 2.8, cz: c.cz - cy*3.4, sx: 5.4, sy: 0.5, sz: 5.4, col: c.col, tall: true });
    } else {
      dynBlocks.push({ cx: c.cx + sy*3.4, cy: 2.4, cz: c.cz - cy*3.4, sx: 3.5, sy: 0.7, sz: 3.5, col: "#475569", tall: true });
    }
    if (c.glassHp > 0) {
      dynBlocks.push({ cx: c.cx - sy*0.6, cy: 3.8, cz: c.cz + cy*0.6, sx: 5.5, sy: 1.45, sz: 5.5, col: "#334155", tall: true });
    }
    if (c.doorTimer && c.doorTimer > 0.02) {
      const openAmt = Math.sin((c.doorTimer / 0.75) * Math.PI);
      const dx = -cy * (4.2 + openAmt * 3.2), dz = -sy * (4.2 + openAmt * 3.2);
      dynBlocks.push({ cx: c.cx + dx, cy: 2.4, cz: c.cz + dz, sx: 2.4, sy: 2.1, sz: 2.4, col: c.col, tall: true });
    }
  }
  dynBlocks.sort((a,b) => Math.hypot(b.cx-camX, b.cz-camZ) - Math.hypot(a.cx-camX, a.cz-camZ));
  for (const s of dynBlocks) drawTop(s);

  // Tia đạn vàng + Hitmarker chữ X khi bắn trúng part có máu ẩn
  if (state.tracerTimer > 0 && state.tracerEnd) {
    const p0 = proj3(state.px, 2.6, state.pz);
    const p1 = proj3(state.tracerEnd[0], 2.2, state.tracerEnd[1]);
    if (p0 && p1) {
      wCtx.strokeStyle = "#fde047"; wCtx.lineWidth = 2.5;
      wCtx.beginPath(); wCtx.moveTo(p0[0], p0[1]); wCtx.lineTo(p1[0], p1[1]); wCtx.stroke();
      wCtx.fillStyle = state.hitShatter ? "#ef4444" : "#ffffff";
      wCtx.font = "bold 16px sans-serif";
      wCtx.fillText("×", p1[0] - 5, p1[1] + 5);
    }
  }

  // Player marker in 3D (khi đi bộ)
  if (!state.drivingCar) {
    const pp = proj3(state.px, 2.2, state.pz);
    if (pp) {
      wCtx.fillStyle = "#38bdf8"; wCtx.strokeStyle = "#fff"; wCtx.lineWidth = 2;
      wCtx.beginPath(); wCtx.arc(pp[0], pp[1], Math.max(4, 900/pp[2]), 0, Math.PI*2); wCtx.fill(); wCtx.stroke();
    }
  }

  // Render Live Rotating GTA V Rectangular Minimap
  const rw = 254, rh = 164, S = 0.52;
  rCtx.fillStyle = "#1c2430"; rCtx.fillRect(0, 0, rw, rh);
  rCtx.save();
  rCtx.translate(rw/2, rh*0.56);
  rCtx.rotate(state.camYaw);
  rCtx.scale(S, S);
  rCtx.translate(-state.px, -state.pz);

  // v22: bản đồ rộng 1 160 stud (±580)
  rCtx.fillStyle = "#2480c6"; rCtx.fillRect(-580, 250, 1160, 140);
  rCtx.fillStyle = "#d6c08e"; rCtx.fillRect(-580, 174, 1160, 76);
  rCtx.fillStyle = "#3a6036"; rCtx.fillRect(-580, -380, 1160, 136);
  for (const p of PLOTS) {
    rCtx.fillStyle = p.plaza ? "#4e9254" : "#343c48";
    rCtx.fillRect(p.cx - p.sx/2, p.cz - p.sz/2, p.sx, p.sz);
  }
  rCtx.fillStyle = "#bab4a8";
  rCtx.fillRect(-14, 57-66, 28, 132); rCtx.fillRect(-83, 57-12, 166, 24); rCtx.fillRect(-48, 57-43, 96, 86);
  rCtx.fillStyle = "#2ea8ce"; rCtx.fillRect(-20, 49-14, 40, 28);
  rCtx.fillStyle = "#ccd6e2";
  for (const r of EW_ROADS) rCtx.fillRect(-580, r.coord - r.width/2, 1160, r.width);
  for (const r of NS_ROADS) rCtx.fillRect(r.coord - r.width/2, -244, r.width, 412);
  rCtx.fillStyle = "#facc15"; rCtx.beginPath(); rCtx.arc(0, 49, 8, 0, Math.PI*2); rCtx.fill();
  for (const c of CARS) {
    rCtx.fillStyle = "#38bdf8"; rCtx.fillRect(c.cx - 5, c.cz - 5, 10, 10);
  }
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

// === 4. RADA GIÁM SÁT ĐA-AGENT & CHUÔNG BÁO NGHIỆM THU ===
let soundEnabled = true;
const alertedKeys = new Set();

function playQaChime() {
  if (!soundEnabled) return;
  try {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();
    const notes = [587.33, 880.0, 1174.66];
    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "triangle";
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.001, ctx.currentTime + idx * 0.14);
      gain.gain.exponentialRampToValueAtTime(0.18, ctx.currentTime + idx * 0.14 + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + idx * 0.14 + 0.32);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(ctx.currentTime + idx * 0.14);
      osc.stop(ctx.currentTime + idx * 0.14 + 0.34);
    });
  } catch (_) {}
}

document.getElementById("soundToggleBtn").onclick = () => {
  soundEnabled = !soundEnabled;
  document.getElementById("soundToggleBtn").textContent = soundEnabled ? "🔔 Chuông báo: BẬT" : "🔕 Chuông báo: TẮT";
  if (soundEnabled) playQaChime();
};
document.getElementById("copyQaCmdBtn").onclick = () => copySafe("Nghiệm thu đi", "lệnh báo Agent Chính");
document.getElementById("refreshRadarBtn").onclick = async () => {
  document.getElementById("radarSummaryTag").textContent = "Đang quét trực tiếp GitHub...";
  await fetch("/api/radar/refresh", { method: "POST" });
  await loadRadar();
};

function escHtml(s) {
  return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

async function loadRadar() {
  try {
    const r = await fetch("/api/radar");
    const d = await r.json();
    const card = document.getElementById("radarCard");
    const banner = document.getElementById("qaBanner");

    document.getElementById("radarSummaryTag").textContent =
      "Agent Phụ mở: " + d.workerBranchCount + " • Chờ nghiệm thu: " + d.pendingQaCount;

    if (d.pendingQaCount > 0) {
      card.classList.add("has-pending");
      banner.classList.add("active");
      const names = d.pendingQaItems.map(p => p.title + " (" + p.shortBranch + ")").join(", ");
      document.getElementById("qaBannerTitle").textContent =
        "🔔 CÓ " + d.pendingQaCount + " CÔNG TRÌNH ĐÃ XONG — CẦN NGHIỆM THU NGAY!";
      document.getElementById("qaBannerDetail").textContent =
        "Hoàn tất: " + names + " — Gõ 'Nghiệm thu đi' vào khung chat để Agent Chính kiểm định 3D & đẩy vào Studio!";
      document.title = "🔔 (" + d.pendingQaCount + " XONG!) CẦN NGHIỆM THU — Los Santos";

      let hasBrandNew = false;
      for (const item of d.pendingQaItems) {
        if (!alertedKeys.has(item.key)) {
          alertedKeys.add(item.key);
          hasBrandNew = true;
        }
      }
      if (hasBrandNew) playQaChime();
    } else {
      card.classList.remove("has-pending");
      banner.classList.remove("active");
      document.title = "GTA V Los Santos — Rada Đa-Agent (" + d.workerBranchCount + " đang chạy)";
    }

    document.getElementById("radarGrid").innerHTML = d.tasks.map(t => {
      let extra = "";
      if (t.precheck) {
        extra = '<div class="plot-sub" style="color:#c4b5fd">' +
          t.precheck.lines + ' dòng • Máu ẩn: ' + t.precheck.integrityMatches +
          (t.precheck.forbiddenTouched.length ? ' • ⚠️ Chạm file cấm!' : ' • 0 conflict') +
          '</div>';
      } else if (t.activeBranch) {
        extra = '<div class="plot-sub">Nhánh: ' + escHtml(t.activeBranch.replace("arena/", "").slice(0, 12)) + ' (' + escHtml(t.relTime) + ')</div>';
      }
      return '<div class="plot-tile ' + t.stateCode + '">' +
        '<div class="plot-head"><span>' + escHtml(t.plotId) + '</span><span>' + escHtml(t.district) + '</span></div>' +
        '<div class="plot-sub" title="' + escHtml(t.title) + '">' + escHtml(t.title) + '</div>' +
        '<div class="plot-status">' + escHtml(t.stateLabel) + '</div>' +
        extra +
      '</div>';
    }).join("");

    if (d.workerBranches && d.workerBranches.length > 0) {
      document.getElementById("workerFeed").innerHTML =
        "🌿 <b>Nhật ký trực tiếp các nhánh Agent Phụ:</b> " +
        d.workerBranches.map(w =>
          '<span style="margin-right:14px"><code>' + escHtml(w.shortId) + '</code> (' + escHtml(w.relTime) + '): ' + escHtml(w.subject) + '</span>'
        ).join(" • ");
    } else {
      document.getElementById("workerFeed").textContent = "🌿 Đang trực tín hiệu từ các tab Arena.ai mới...";
    }
  } catch (_) {}
}
loadRadar();
setInterval(loadRadar, 4000);
</script>
</body>
</html>`;

// Bộ đệm Rada tự động quét GitHub nền mỗi 7 giây
let cachedRadar = computeRadarSnapshot({ doSyncFetch: false });
let fetchInFlight = false;
async function refreshRadarInBackground() {
	if (fetchInFlight) return cachedRadar;
	fetchInFlight = true;
	try {
		await triggerGitFetchAsync();
		cachedRadar = computeRadarSnapshot({ doSyncFetch: false });
	} catch {
		// giữ bản cũ nếu mạng chập chờn
	} finally {
		fetchInFlight = false;
	}
	return cachedRadar;
}
refreshRadarInBackground();
setInterval(refreshRadarInBackground, 7000);

const server = http.createServer(async (req, res) => {
	const url = new URL(req.url || "/", "http://localhost");
	if (url.pathname === "/") {
		res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
		res.end(HTML);
		return;
	}
	if (url.pathname === "/lscustoms") {
		res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
		res.end(fs.readFileSync(path.join(REPO_ROOT, "bridge", "lscustoms-demo.html"), "utf8"));
		return;
	}
	if (url.pathname === "/hud" || url.pathname === "/weapon-wheel") {
		res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
		res.end(fs.readFileSync(path.join(REPO_ROOT, "bridge", "hud-demo.html"), "utf8"));
		return;
	}
	if (url.pathname === "/city" || url.pathname === "/city-life" || url.pathname === "/city-demo") {
		res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
		res.end(fs.readFileSync(path.join(REPO_ROOT, "bridge", "city-life-demo.html"), "utf8"));
		return;
	}
	if (url.pathname === "/npc" || url.pathname === "/npc-demo") {
		res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
		res.end(fs.readFileSync(path.join(REPO_ROOT, "bridge", "npc-demo.html"), "utf8"));
		return;
	}
	if (url.pathname === "/api/radar") {
		res.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
		res.end(JSON.stringify(cachedRadar));
		return;
	}
	if (url.pathname === "/api/radar/refresh") {
		const fresh = await refreshRadarInBackground();
		res.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
		res.end(JSON.stringify(fresh));
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
