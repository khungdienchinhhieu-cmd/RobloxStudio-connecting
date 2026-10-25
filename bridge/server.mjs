import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import {
	REPO_ROOT,
	GITHUB_OWNER,
	GITHUB_REPO,
	GITHUB_BRANCH,
	loadExistingBundle,
	compileSyncBundle,
	buildGitHubCommandBarOneLiner,
} from "./compiler.mjs";

const PORT = Number(process.env.BRIDGE_PORT || 8080);
const HOST = "0.0.0.0";
const PLUGIN_FILE = path.join(REPO_ROOT, "plugin", "StudioLiveBridge.server.luau");

const HTML = `<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Arena ↔ Roblox Studio Live Sync</title>
<style>
  :root {
    --bg: #0f1117;
    --card: #181c26;
    --card-alt: #11141d;
    --border: #2a3145;
    --text: #eef2ff;
    --muted: #94a3b8;
    --primary: #3b82f6;
    --primary-hover: #2563eb;
    --green: #10b981;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.5;
    padding: 20px;
  }
  .container { max-width: 900px; margin: 0 auto; display: flex; flex-direction: column; gap: 16px; }
  .header {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 18px 20px;
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
  }
  .header h1 { font-size: 18px; font-weight: 700; }
  .header p { font-size: 13px; color: var(--muted); margin-top: 2px; }
  .badge {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 7px 14px;
    border-radius: 999px;
    font-size: 13px;
    font-weight: 600;
    background: rgba(16, 185, 129, 0.15);
    color: #6ee7b7;
    border: 1px solid rgba(16, 185, 129, 0.4);
  }
  .dot { width: 9px; height: 9px; border-radius: 50%; background: currentColor; }
  .card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 18px 20px;
  }
  .card h2 { font-size: 15px; font-weight: 700; margin-bottom: 6px; }
  .sub { font-size: 13px; color: var(--muted); margin-bottom: 12px; }
  .code-box {
    background: var(--card-alt);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 12px;
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    font-size: 12px;
    color: #bfdbfe;
    overflow-x: auto;
    white-space: nowrap;
    margin-bottom: 10px;
    user-select: all;
  }
  .btn-row { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  button {
    background: var(--primary);
    color: #fff;
    border: none;
    border-radius: 8px;
    padding: 9px 15px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
  }
  button:hover { background: var(--primary-hover); }
  button.secondary { background: #262d40; color: #e2e8f0; border: 1px solid var(--border); }
  .steps { margin-top: 12px; padding-left: 18px; font-size: 13px; color: #cbd5e1; display: flex; flex-direction: column; gap: 4px; }
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  @media (max-width: 700px) { .grid-2 { grid-template-columns: 1fr; } }
  .list { display: flex; flex-direction: column; gap: 6px; max-height: 220px; overflow-y: auto; }
  .list-item {
    background: var(--card-alt);
    border: 1px solid var(--border);
    border-radius: 7px;
    padding: 8px 10px;
    font-size: 12px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .tag { font-size: 11px; padding: 2px 7px; border-radius: 4px; background: #252d42; color: #93c5fd; }
  .toast { font-size: 12px; color: #6ee7b7; font-weight: 600; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <div>
      <h1>⚡ Cầu nối GitHub Live Sync ↔ Roblox Studio</h1>
      <p id="repoMeta">Đang tải thông tin nhánh đồng bộ...</p>
    </div>
    <div class="badge"><span class="dot"></span><span id="verText">GitHub Live Sync Sẵn Sàng</span></div>
  </div>

  <div class="card">
    <h2>🚀 Dán 1 dòng này vào Command Bar của Roblox Studio (Không bị chặn Proxy/Cookie)</h2>
    <p class="sub">Kết nối thẳng qua <code>api.github.com</code> tới repo của bạn — tự động đồng bộ mọi thay đổi Rojo và tác vụ dựng Map/UI sau ~3 giây.</p>
    <div id="oneLinerBox" class="code-box">Đang tải...</div>
    <div class="btn-row">
      <button id="copyCmdBtn">📋 Sao chép lệnh Command Bar</button>
      <button id="copyPluginBtn" class="secondary">📦 Sao chép toàn bộ mã Local Plugin</button>
      <span id="toast" class="toast"></span>
    </div>
    <ol class="steps">
      <li>Mở <b>Roblox Studio</b> → vào <b>View</b> → bật <b>Command Bar</b>.</li>
      <li>Dán dòng lệnh mới ở trên vào <b>Command Bar</b> rồi nhấn <b>Enter</b> (chọn <b>Allow</b> nếu Studio hỏi quyền HTTP tới <code>api.github.com</code>).</li>
      <li>Bảng <b>Arena ↔ Studio Live Bridge</b> sẽ hiện góc dưới bên phải với trạng thái <b>● ĐÃ KẾT NỐI TRỰC TIẾP</b>.</li>
    </ol>
  </div>

  <div class="grid-2">
    <div class="card">
      <h2>📁 Các Script Rojo đang phát trực tuyến</h2>
      <p class="sub">Tự động cập nhật vào Explorer của Studio.</p>
      <div id="filesList" class="list"></div>
    </div>
    <div class="card">
      <h2>✨ Tác vụ Dựng Map / Instance gần đây</h2>
      <p class="sub">Chạy 1 lần tự động kèm hỗ trợ hoàn tác <code>Ctrl + Z</code>.</p>
      <div id="actionsList" class="list"></div>
    </div>
  </div>
</div>
<script>
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
    document.getElementById("verText").textContent = "Sync v" + d.bundle.version + " (" + d.bundle.files.length + " script)";
    document.getElementById("filesList").innerHTML = d.bundle.files.map(f =>
      '<div class="list-item"><span>' + f.repoPath + '</span><span class="tag">' + f.className + '</span></div>'
    ).join("");
    const acts = d.bundle.actions || [];
    document.getElementById("actionsList").innerHTML = acts.length
      ? acts.slice().reverse().map(a => '<div class="list-item"><span>' + a.description + '</span><span class="tag">' + a.id + '</span></div>').join("")
      : '<div class="list-item"><span>Sẵn sàng nhận yêu cầu dựng Map / UI từ bạn</span><span class="tag">Idle</span></div>';
  }
  load();
  setInterval(load, 2500);
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
		const bundle = fs.existsSync( path.join(REPO_ROOT, "studio-sync.json") )
			? loadExistingBundle()
			: compileSyncBundle();
		res.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
		res.end(
			JSON.stringify({
				repo: `${GITHUB_OWNER}/${GITHUB_REPO}`,
				branch: GITHUB_BRANCH,
				oneLiner: buildGitHubCommandBarOneLiner(),
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
	console.log(`[Arena GitHub Live Sync Dashboard] Listening on http://${HOST}:${PORT}`);
});
