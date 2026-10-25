#!/usr/bin/env node
/**
 * bridge/agent-radio.mjs
 * BỘ ĐÀM ĐA-AGENT XUYÊN NHÁNH (CROSS-BRANCH GIT RADIO — 0% HTTP 403, 0% MERGE CONFLICT!)
 *
 * Cơ chế hoạt động thông minh cho nhiều phiên Arena.ai chạy song song:
 *  - Nếu dùng chung 1 file `CHAT.md`, các nhánh chưa Merge sẽ không thấy nhau và khi Merge PR sẽ bị Conflict 100%.
 *  - Thay vào đó:
 *    1) Khi gọi `say <MaO> "Tin nhắn..."`: Agent ghi vào file RIÊNG mang mã nhánh của mình
 *       (`agents/notes/<MaO>__<idNhanh>.md`) rồi commit & push lên nhánh `origin/arena/...` của chính phiên đó.
 *       -> Mỗi phiên một tên file độc lập => Gộp 10 PR vào `main` KHÔNG BAO GIỜ XUNG ĐỘT GIT!
 *    2) Khi gọi `read`: Script tự chạy `git fetch origin --prune --quiet` và quét TẤT CẢ các nhánh `origin/arena/*`
 *       cùng `origin/main` trên GitHub để đọc trực tiếp mọi tin nhắn `agents/notes/*.md` của tất cả các phiên Arena khác
 *       NGAY LẬP TỨC dù chưa nhánh nào Merge vào `main`!
 *
 * Cách dùng:
 *   node bridge/agent-radio.mjs read
 *   node bridge/agent-radio.mjs say Plot_C1 "Đang dựng LS Customs, cổng xe vào tại Z=123, X từ -228 đến -208"
 */

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { REPO_ROOT, getCurrentGitBranch } from "./compiler.mjs";

const NOTES_REL_DIR = "agents/notes";
const NOTES_ABS_DIR = path.join(REPO_ROOT, NOTES_REL_DIR);

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

function readAllBranchesRadio() {
	console.log("======================================================================");
	console.log("📡 BỘ ĐÀM ĐA-AGENT XUYÊN NHÁNH (Đang đồng bộ tất cả phiên Arena.ai...)");
	console.log("======================================================================");

	runGit(["fetch", "origin", "--prune", "--quiet"], true);

	const rawBranches = runGit(["branch", "-r", "--format=%(refname:short)"], true);
	const remoteBranches = rawBranches
		.split("\n")
		.map((b) => b.trim())
		.filter((b) => b.startsWith("origin/") && !b.includes("HEAD"));

	const seenContentByNote = new Map();

	for (const ref of remoteBranches) {
		const treeList = runGit(["ls-tree", "--name-only", ref, `${NOTES_REL_DIR}/`], true);
		if (!treeList) continue;

		for (const fileRel of treeList.split("\n").map((s) => s.trim()).filter(Boolean)) {
			if (!fileRel.endsWith(".md")) continue;
			const content = runGit(["show", `${ref}:${fileRel}`], true);
			if (!content) continue;

			const prev = seenContentByNote.get(fileRel);
			// Ưu tiên hiển thị bản mới trên nhánh arena/* hoặc nếu nội dung khác
			if (!prev || ref.startsWith("origin/arena/")) {
				seenContentByNote.set(fileRel, { ref, fileRel, content });
			}
		}
	}

	if (seenContentByNote.size === 0) {
		console.log("(Chưa có bản tin nào từ các phiên Agent khác.)");
		return;
	}

	const entries = [...seenContentByNote.values()].sort((a, b) =>
		a.fileRel.localeCompare(b.fileRel)
	);

	for (const item of entries) {
		console.log(`\n📌 Nguồn: [${item.ref}] -> ${item.fileRel}`);
		console.log("----------------------------------------------------------------------");
		console.log(item.content);
	}
	console.log("\n======================================================================");
}

function sayToRadio(topicRaw, messageText) {
	if (!topicRaw || !messageText) {
		console.error(
			'Cách dùng: node bridge/agent-radio.mjs say <MaO_Hoac_ChuDe> "Nội dung nhắn cho các Agent khác..."'
		);
		process.exit(1);
	}

	const branch = getCurrentGitBranch();
	const shortId = getBranchShortId(branch);
	const cleanTopic = topicRaw.replace(/[^a-zA-Z0-9_-]/g, "_");
	const fileName = `${cleanTopic}__${shortId}.md`;
	const absPath = path.join(NOTES_ABS_DIR, fileName);

	fs.mkdirSync(NOTES_ABS_DIR, { recursive: true });

	const timestamp = new Date().toISOString();
	let prevLog = "";
	if (fs.existsSync(absPath)) {
		prevLog = fs.readFileSync(absPath, "utf8").trim() + "\n\n";
	} else {
		prevLog = `# 📡 Bản Tin Điều Phối — \`${cleanTopic}\` (Nhánh \`${branch}\`)\n\n`;
	}

	const entry = `${prevLog}- **[${timestamp}]** ${messageText.trim()}\n`;
	fs.writeFileSync(absPath, entry, "utf8");

	runGit(["add", absPath]);
	const status = runGit(["status", "--porcelain", absPath]);
	if (status) {
		runGit(["commit", "-m", `docs(agent-radio): update ${cleanTopic} note from ${shortId}`]);
		runGit(["push", "-u", "origin", branch]);
	}

	console.log(`✅ Đã phát bản tin lên nhánh ${branch} (${NOTES_REL_DIR}/${fileName})!`);
	console.log(`   Mọi phiên Arena.ai khác gõ 'node bridge/agent-radio.mjs read' sẽ thấy ngay lập tức!`);
}

const mode = process.argv[2] || "read";
if (mode === "read") {
	readAllBranchesRadio();
} else if (mode === "say" || mode === "post") {
	const topic = process.argv[3];
	const msg = process.argv.slice(4).join(" ");
	sayToRadio(topic, msg);
} else {
	console.log(
		'Cách dùng:\n  node bridge/agent-radio.mjs read\n  node bridge/agent-radio.mjs say <MaO> "Tin nhắn..."'
	);
}
