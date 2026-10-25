#!/usr/bin/env node
/**
 * bridge/agent-radio.mjs
 * HỆ THỐNG BỘ ĐÀM & TỰ ĐỘNG PHÂN VIỆC / NGHIỆM THU ĐA-AGENT XUYÊN NHÁNH
 * (0% HTTP 403, 0% Git Merge Conflict — Agent Chính điều phối & nghiệm thu, Agent Phụ tự nhận việc!)
 *
 * Các lệnh hỗ trợ:
 *   node bridge/agent-radio.mjs status                       -> Xem bảng trạng thái toàn bộ công trình & các nhánh Agent Phụ
 *   node bridge/agent-radio.mjs read                         -> Đọc toàn bộ bản tin bộ đàm xuyên tất cả nhánh origin/arena/*
 *   node bridge/agent-radio.mjs claim [auto | TASK_ID]       -> (Agent Phụ) Tự động khoá & nhận 1 công trình chưa có ai làm
 *   node bridge/agent-radio.mjs submit <TASK_ID> "Báo cáo"   -> (Agent Phụ) Gửi nộp bài lên Bộ Đàm để Agent Chính nghiệm thu
 *   node bridge/agent-radio.mjs say <ChuDe> "Tin nhắn..."    -> Phát tin nhắn phối hợp toạ độ bất kỳ
 */

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { REPO_ROOT, getCurrentGitBranch } from "./compiler.mjs";

const NOTES_REL_DIR = "agents/notes";
const NOTES_ABS_DIR = path.join(REPO_ROOT, NOTES_REL_DIR);
const BOARD_PATH = path.join(REPO_ROOT, "agents", "AGENT_TASK_BOARD.json");

function runGit(args, allowFail = false) {
	try {
		return execFileSync("git", args, { cwd: REPO_ROOT, encoding: "utf8" }).trim();
	} catch (err) {
		if (allowFail) return "";
		throw err;
	}
}

function getBranchShortId(branchName) {
	const m = branchName.match(/^arena\/([a-z0-9]+)/i);
	if (m) return m[1];
	return branchName.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 16);
}

function loadBoard() {
	return JSON.parse(fs.readFileSync(BOARD_PATH, "utf8"));
}

function scanRemoteState() {
	runGit(["fetch", "origin", "+refs/heads/*:refs/remotes/origin/*", "--prune", "--quiet"], true);

	const rawBranches = runGit(["branch", "-r", "--format=%(refname:short)"], true);
	const remoteBranches = rawBranches
		.split("\n")
		.map((b) => b.trim())
		.filter((b) => b.startsWith("origin/") && !b.includes("HEAD"));

	const notes = new Map();
	const claimedByTask = new Map();
	const submittedByTask = new Map();
	const moduleRefByPath = new Map();

	for (const ref of remoteBranches) {
		const noteFiles = runGit(["ls-tree", "--name-only", ref, `${NOTES_REL_DIR}/`], true);
		if (noteFiles) {
			for (const fileRel of noteFiles.split("\n").map((s) => s.trim()).filter(Boolean)) {
				if (!fileRel.endsWith(".md")) continue;
				const content = runGit(["show", `${ref}:${fileRel}`], true);
				if (!content) continue;
				if (!notes.has(fileRel) || ref.startsWith("origin/arena/")) {
					notes.set(fileRel, { ref, fileRel, content });
				}
				const base = path.basename(fileRel, ".md");
				const claimMatch = base.match(/^CLAIM_(.+)__([a-zA-Z0-9_-]+)$/);
				if (claimMatch) {
					claimedByTask.set(claimMatch[1], { ref, fileRel, content });
				}
				const submitMatch = base.match(/^SUBMIT_(.+)__([a-zA-Z0-9_-]+)$/);
				if (submitMatch) {
					submittedByTask.set(submitMatch[1], { ref, fileRel, content });
				}
			}
		}

		const modFiles = runGit(["ls-tree", "--name-only", ref, "src/shared/World/Modules/"], true);
		if (modFiles) {
			for (const modRel of modFiles.split("\n").map((s) => s.trim()).filter(Boolean)) {
				if (!modRel.endsWith(".luau")) continue;
				if (!moduleRefByPath.has(modRel) || ref.startsWith("origin/arena/")) {
					moduleRefByPath.set(modRel, ref);
				}
			}
		}
	}

	return { remoteBranches, notes, claimedByTask, submittedByTask, moduleRefByPath };
}

function writeAndPushNote(fileName, content, commitMsg) {
	const branch = getCurrentGitBranch();
	fs.mkdirSync(NOTES_ABS_DIR, { recursive: true });
	const absPath = path.join(NOTES_ABS_DIR, fileName);
	fs.writeFileSync(absPath, content, "utf8");

	runGit(["add", absPath]);
	const status = runGit(["status", "--porcelain", absPath]);
	if (status) {
		runGit(["commit", "-m", commitMsg]);
		runGit(["push", "-u", "origin", branch]);
	}
	return { branch, relPath: `${NOTES_REL_DIR}/${fileName}` };
}

function showStatus() {
	const board = loadBoard();
	const state = scanRemoteState();

	console.log("================================================================================");
	console.log("🏗️  BẢNG ĐIỀU PHỐI & NGHIỆM THU ĐA-AGENT (LOS SANTOS MASTER DISPATCH)");
	console.log("================================================================================");

	for (const t of board.tasks) {
		let badge = "🟢 TRỐNG (Sẵn sàng nhận)";
		let branchInfo = "";

		if (t.status === "completed") {
			badge = "✅ ĐÃ HOÀN THÀNH (Nền chính)";
		} else if (state.submittedByTask.has(t.taskId)) {
			const sub = state.submittedByTask.get(t.taskId);
			badge = "🟣 CHỜ AGENT CHÍNH NGHIỆM THU";
			branchInfo = ` [Nhánh: ${sub.ref}]`;
		} else if (state.moduleRefByPath.has(t.modulePath)) {
			const ref = state.moduleRefByPath.get(t.modulePath);
			badge = "🔵 ĐÃ CÓ FILE MODULE (Kiểm tra/Nghiệm thu)";
			branchInfo = ` [Nhánh: ${ref}]`;
		} else if (state.claimedByTask.has(t.taskId)) {
			const cl = state.claimedByTask.get(t.taskId);
			badge = "🟡 ĐANG THI CÔNG";
			branchInfo = ` [Nhánh: ${cl.ref}]`;
		}

		console.log(`• ${t.taskId} — ${t.title} (${t.plotId})`);
		console.log(`    Trạng thái : ${badge}${branchInfo}`);
		console.log(`    File đích  : ${t.modulePath}`);
	}
	console.log("================================================================================");
}

function readAllBranchesRadio() {
	const state = scanRemoteState();
	console.log("======================================================================");
	console.log("📡 BỘ ĐÀM ĐA-AGENT XUYÊN NHÁNH (Tất cả phiên Arena.ai đang hoạt động)");
	console.log("======================================================================");

	if (state.notes.size === 0) {
		console.log("(Chưa có bản tin nào.)");
		return;
	}

	const entries = [...state.notes.values()].sort((a, b) => a.fileRel.localeCompare(b.fileRel));
	for (const item of entries) {
		console.log(`\n📌 Nguồn: [${item.ref}] -> ${item.fileRel}`);
		console.log("----------------------------------------------------------------------");
		console.log(item.content.trim());
	}
	console.log("\n======================================================================");
}

function claimTask(requestedId = "auto") {
	const board = loadBoard();
	const state = scanRemoteState();
	const branch = getCurrentGitBranch();
	const shortId = getBranchShortId(branch);

	let chosen = null;
	if (!requestedId || requestedId === "auto") {
		for (const t of board.tasks) {
			if (t.status === "completed") continue;
			if (state.submittedByTask.has(t.taskId)) continue;
			if (state.claimedByTask.has(t.taskId)) continue;
			if (state.moduleRefByPath.has(t.modulePath)) continue;
			chosen = t;
			break;
		}
	} else {
		chosen = board.tasks.find(
			(t) =>
				t.taskId.toLowerCase() === requestedId.toLowerCase() ||
				(t.plotId && t.plotId.toLowerCase() === requestedId.toLowerCase())
		);
	}

	if (!chosen) {
		console.error("❌ Hiện không còn hạng mục trống nào hoặc mã TASK_ID không hợp lệ!");
		showStatus();
		process.exit(1);
	}

	const content = [
		`# 🟡 NHẬN NHIỆM VỤ: \`${chosen.taskId}\` — ${chosen.title}`,
		`- **Nhánh Agent Phụ:** \`${branch}\``,
		`- **Ô đất (` + "Plot" + `):** \`${chosen.plotId}\` (${chosen.district})`,
		`- **File module sẽ tạo:** \`${chosen.modulePath}\``,
		`- **Thời điểm nhận:** ${new Date().toISOString()}`,
		"",
	].join("\n");

	writeAndPushNote(
		`CLAIM_${chosen.taskId}__${shortId}.md`,
		content,
		`docs(agent-radio): claim ${chosen.taskId} on ${shortId}`
	);

	const b = chosen.buildableBounds;
	console.log("================================================================================");
	console.log(`🎯 ĐÃ KHOÁ & NHẬN VIỆC THÀNH CÔNG: ${chosen.taskId}`);
	console.log("================================================================================");
	console.log(`🏛️  Công trình      : ${chosen.title} (${chosen.district})`);
	console.log(`📍 Ô đất           : ${chosen.plotId}`);
	console.log(
		`📐 Ranh giới xây   : X từ ${b.minX} đến ${b.maxX} | Z từ ${b.minZ} đến ${b.maxZ} | Cao độ nền Y = ${b.groundY}`
	);
	console.log(`📁 File DUY NHẤT   : ${chosen.modulePath}`);
	console.log(`🔢 Thứ tự Order    : ${chosen.order}`);
	console.log(`📝 Yêu cầu chi tiết: ${chosen.spec}`);
	console.log("--------------------------------------------------------------------------------");
	console.log("⚠️  QUY TẮC BẮT BUỘC ĐỂ AGENT CHÍNH NGHIỆM THU ĐẠT 100%:");
	console.log(`  1. CHỈ tạo file '${chosen.modulePath}' (CẤM sửa file lõi chung, CẤM sửa studio-sync.json!).`);
	console.log("  2. Mọi tường gạch, ô kính, cột, biển hiệu, đồ nội thất PHẢI dùng PartBuilder có truyền máu ẩn `integrity`.");
	console.log("  3. Cửa đi bộ cao >= 8.0 studs; cửa cuốn ô tô rộng >= 15 studs, cao >= 11 studs; không đặt sàn trùng Y=1.15.");
	console.log("  4. Biên dịch kiểm tra bằng @luau-rs/luau và render ảnh PNG 3D kiểm tra ngoại thất + nội thất bằng mắt.");
	console.log(
		`  5. Khi hoàn tất & commit file .luau lên nhánh của bạn, chạy lệnh nộp bài cho Agent Chính:\n     node bridge/agent-radio.mjs submit ${chosen.taskId} "Mô tả ngắn + toạ độ cổng chính"`
	);
	console.log("================================================================================");
}

function submitTask(taskId, summaryText) {
	if (!taskId || !summaryText) {
		console.error('Cách dùng: node bridge/agent-radio.mjs submit <TASK_ID> "Báo cáo bàn giao & toạ độ cổng..."');
		process.exit(1);
	}
	const branch = getCurrentGitBranch();
	const shortId = getBranchShortId(branch);
	const content = [
		`# 🟣 BÀN GIAO CHỜ NGHIỆM THU: \`${taskId}\``,
		`- **Nhánh Agent Phụ:** \`${branch}\``,
		`- **Thời điểm nộp:** ${new Date().toISOString()}`,
		`- **Báo cáo chi tiết & Toạ độ khớp nối:**`,
		`  ${summaryText.trim()}`,
		"",
	].join("\n");

	const res = writeAndPushNote(
		`SUBMIT_${taskId}__${shortId}.md`,
		content,
		`docs(agent-radio): submit ${taskId} for Master QA from ${shortId}`
	);
	console.log(`✅ Đã nộp bài '${taskId}' lên Bộ Đàm (${res.relPath} trên nhánh ${res.branch})!`);
	console.log("👉 Giờ người dùng chỉ cần báo Agent Chính 'Nghiệm thu đi' là công trình sẽ được kiểm định & đưa vào Studio!");
}

function sayToRadio(topicRaw, messageText) {
	if (!topicRaw || !messageText) {
		console.error('Cách dùng: node bridge/agent-radio.mjs say <ChuDe> "Nội dung nhắn..."');
		process.exit(1);
	}
	const branch = getCurrentGitBranch();
	const shortId = getBranchShortId(branch);
	const cleanTopic = topicRaw.replace(/[^a-zA-Z0-9_-]/g, "_");
	const fileName = `${cleanTopic}__${shortId}.md`;
	const absPath = path.join(NOTES_ABS_DIR, fileName);

	fs.mkdirSync(NOTES_ABS_DIR, { recursive: true });
	const prev = fs.existsSync(absPath)
		? fs.readFileSync(absPath, "utf8").trim() + "\n\n"
		: `# 📡 Bản Tin Điều Phối — \`${cleanTopic}\` (Nhánh \`${branch}\`)\n\n`;

	writeAndPushNote(
		fileName,
		`${prev}- **[${new Date().toISOString()}]** ${messageText.trim()}\n`,
		`docs(agent-radio): update ${cleanTopic} note from ${shortId}`
	);
	console.log(`✅ Đã phát bản tin lên nhánh ${branch} (${NOTES_REL_DIR}/${fileName})!`);
}

const mode = process.argv[2] || "status";
if (mode === "status") {
	showStatus();
} else if (mode === "read") {
	readAllBranchesRadio();
} else if (mode === "claim") {
	claimTask(process.argv[3] || "auto");
} else if (mode === "submit") {
	submitTask(process.argv[3], process.argv.slice(4).join(" "));
} else if (mode === "say" || mode === "post") {
	sayToRadio(process.argv[3], process.argv.slice(4).join(" "));
} else {
	console.log(
		[
			"Cách dùng Bộ Đàm & Điều Phối Đa-Agent:",
			"  node bridge/agent-radio.mjs status",
			"  node bridge/agent-radio.mjs read",
			"  node bridge/agent-radio.mjs claim auto",
			'  node bridge/agent-radio.mjs submit <TASK_ID> "Báo cáo bàn giao..."',
			'  node bridge/agent-radio.mjs say <ChuDe> "Tin nhắn..."',
		].join("\n")
	);
}
