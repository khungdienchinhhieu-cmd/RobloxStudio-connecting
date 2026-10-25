#!/usr/bin/env node
/**
 * bridge/qa-radar.mjs
 * TRẠM RADA QUÉT TỰ ĐỘNG CÁC AGENT PHỤ & PHÁT TÍN HIỆU NGHIỆM THU (REAL-TIME QA RADAR)
 *
 * - Tự động `git fetch origin --prune` (bất đồng bộ trên server hoặc đồng bộ qua CLI).
 * - So sánh mọi nhánh `origin/arena/*` với nhánh Điều Phối Chính (`arena/b37b6115-robloxstudio-connecting`):
 *   + Nhánh nào vừa chạy `claim` -> 🟡 ĐANG THI CÔNG
 *   + Nhánh nào đã nộp `SUBMIT_*.md` hoặc đã push `src/shared/World/Modules/*.luau` mà chưa gộp vào nhánh Chính
 *     -> 🔔 CẦN NGHIỆM THU NGAY! (kèm kiểm tra sơ bộ: số dòng, số lệnh máu ẩn `integrity`, có phạm quy sửa file cấm không).
 *   + Nhánh nào đã được nhánh Chính tích hợp file `.luau` cùng mã hash -> ✅ ĐÃ NGHIỆM THU & LÊN STUDIO!
 */

import fs from "node:fs";
import path from "node:path";
import { execFile, execFileSync } from "node:child_process";
import { REPO_ROOT, getCurrentGitBranch } from "./compiler.mjs";

const BOARD_PATH = path.join(REPO_ROOT, "agents", "AGENT_TASK_BOARD.json");
const NOTES_REL_DIR = "agents/notes";

function gitSync(args) {
	try {
		return execFileSync("git", args, { cwd: REPO_ROOT, encoding: "utf8" }).trim();
	} catch {
		return "";
	}
}

export function triggerGitFetchAsync() {
	return new Promise((resolve) => {
		execFile(
			"git",
			["fetch", "origin", "+refs/heads/*:refs/remotes/origin/*", "--prune", "--quiet"],
			{ cwd: REPO_ROOT, timeout: 12000 },
			() => resolve()
		);
	});
}

export function computeRadarSnapshot({ doSyncFetch = false } = {}) {
	if (doSyncFetch) {
		gitSync(["fetch", "origin", "+refs/heads/*:refs/remotes/origin/*", "--prune", "--quiet"]);
	}

	const board = JSON.parse(fs.readFileSync(BOARD_PATH, "utf8"));
	const masterBranch = board.masterCoordinatorBranch || getCurrentGitBranch();
	const masterRef = gitSync(["rev-parse", "--verify", `origin/${masterBranch}`])
		? `origin/${masterBranch}`
		: "HEAD";

	// Các module đã được tích hợp vào nhánh Chính (Master Coordinator)
	const masterModuleBlobs = new Map();
	const masterModsRaw = gitSync(["ls-tree", masterRef, "src/shared/World/Modules/"]);
	if (masterModsRaw) {
		for (const line of masterModsRaw.split("\n").filter(Boolean)) {
			// <mode> <type> <blobSha>\t<path>
			const parts = line.split(/\s+/);
			const tabIdx = line.indexOf("\t");
			if (parts.length >= 3 && tabIdx !== -1) {
				masterModuleBlobs.set(line.slice(tabIdx + 1).trim(), parts[2]);
			}
		}
	}

	// Liệt kê toàn bộ nhánh origin/arena/* kèm thời gian commit mới nhất
	const refsRaw = gitSync([
		"for-each-ref",
		"--sort=-committerdate",
		"--format=%(refname:short)|%(committerdate:iso8601)|%(committerdate:relative)|%(contents:subject)|%(objectname:short)",
		"refs/remotes/origin/arena/",
	]);

	const workerBranches = [];
	const claimsByTask = new Map();
	const submitsByTask = new Map();
	const workerModuleByPath = new Map();

	const forbiddenSet = new Set(board.zeroConflictContract?.forbiddenSharedEdits || []);

	for (const row of refsRaw.split("\n").filter(Boolean)) {
		const [ref, isoDate, relTime, subject, shortSha] = row.split("|");
		const branchName = ref.replace(/^origin\//, "");
		const isMaster = branchName === masterBranch;

		// Quét notes trên nhánh này
		const noteFiles = gitSync(["ls-tree", "--name-only", ref, `${NOTES_REL_DIR}/`]);
		const branchClaims = [];
		const branchSubmits = [];
		if (noteFiles) {
			for (const nf of noteFiles.split("\n").map((s) => s.trim()).filter(Boolean)) {
				const base = path.basename(nf, ".md");
				const cm = base.match(/^CLAIM_(.+)__([a-zA-Z0-9_-]+)$/);
				if (cm && !isMaster) {
					const content = gitSync(["show", `${ref}:${nf}`]);
					const info = { ref, branchName, relTime, shortSha, subject, notePath: nf, content };
					claimsByTask.set(cm[1], info);
					branchClaims.push(cm[1]);
				}
				const sm = base.match(/^SUBMIT_(.+)__([a-zA-Z0-9_-]+)$/);
				if (sm && !isMaster) {
					const content = gitSync(["show", `${ref}:${nf}`]);
					const info = { ref, branchName, relTime, shortSha, subject, notePath: nf, content };
					submitsByTask.set(sm[1], info);
					branchSubmits.push(sm[1]);
				}
			}
		}

		// Quét các file module mới trên nhánh Agent Phụ
		if (!isMaster) {
			const modTree = gitSync(["ls-tree", ref, "src/shared/World/Modules/"]);
			const builtModules = [];
			if (modTree) {
				for (const line of modTree.split("\n").filter(Boolean)) {
					const parts = line.split(/\s+/);
					const tabIdx = line.indexOf("\t");
					if (parts.length < 3 || tabIdx === -1) continue;
					const modPath = line.slice(tabIdx + 1).trim();
					const blobSha = parts[2];
					if (modPath.endsWith("RegistryHealthcheck.luau")) continue;

					// Đọc code kiểm tra nhanh
					const src = gitSync(["show", `${ref}:${modPath}`]);
					const lines = src ? src.split("\n").length : 0;
					const integrityMatches = src ? (src.match(/integrity|brickWall|segmentedRow/g) || []).length : 0;
					const hasBuildFn = src ? /function\s+\w+\.build\s*\(/.test(src) || /build\s*=\s*function/.test(src) : false;

					// Kiểm tra xem có sửa nhầm file cấm không
					const mergeBase = gitSync(["merge-base", masterRef, ref]) || masterRef;
					const touchedRaw = gitSync(["diff", "--name-only", `${mergeBase}..${ref}`]);
					const forbiddenTouched = touchedRaw
						.split("\n")
						.map((s) => s.trim())
						.filter((f) => f && forbiddenSet.has(f));

					const precheck = {
						modPath,
						blobSha,
						lines,
						bytes: src.length,
						integrityMatches,
						hasBuildFn,
						forbiddenTouched,
						alreadyIntegrated: masterModuleBlobs.get(modPath) === blobSha,
					};
					builtModules.push(precheck);
					if (!workerModuleByPath.has(modPath)) {
						workerModuleByPath.set(modPath, { ref, branchName, relTime, shortSha, subject, precheck });
					}
				}
			}

			workerBranches.push({
				ref,
				branchName,
				isoDate,
				relTime,
				subject,
				shortSha,
				claims: branchClaims,
				submits: branchSubmits,
				builtModules,
			});
		}
	}

	const tasksReport = [];
	const pendingQaItems = [];

	for (const t of board.tasks) {
		const modInfo = workerModuleByPath.get(t.modulePath);
		const subInfo = submitsByTask.get(t.taskId);
		const claimInfo = claimsByTask.get(t.taskId);
		const integratedInMaster =
			t.status === "completed" ||
			(masterModuleBlobs.has(t.modulePath) &&
				(!modInfo || modInfo.precheck.alreadyIntegrated));

		let stateCode = "FREE";
		let stateLabel = "🟢 TRỐNG — Chờ Agent nhận";
		let activeBranch = null;
		let relTime = "";
		let precheck = modInfo ? modInfo.precheck : null;
		let submitSummary = "";

		if (integratedInMaster) {
			stateCode = "INTEGRATED";
			stateLabel = "✅ ĐÃ NGHIỆM THU & VÀO STUDIO";
		} else if (subInfo || (modInfo && !modInfo.precheck.alreadyIntegrated)) {
			stateCode = subInfo ? "NEEDS_QA_SUBMITTED" : "NEEDS_QA_MODULE_PUSHED";
			stateLabel = subInfo
				? "🔔 ĐÃ NỘP BÀI — CẦN NGHIỆM THU NGAY!"
				: "🟣 ĐÃ PUSH FILE .LUAU — SẴN SÀNG NGHIỆM THU!";
			activeBranch = (subInfo || modInfo).branchName;
			relTime = (subInfo || modInfo).relTime;
			if (subInfo) {
				submitSummary = subInfo.content
					.split("\n")
					.filter((l) => !l.startsWith("#"))
					.join(" ")
					.trim()
					.slice(0, 220);
			}
			pendingQaItems.push({
				taskId: t.taskId,
				title: t.title,
				plotId: t.plotId,
				modulePath: t.modulePath,
				branchName: activeBranch,
				relTime,
				submittedExplicitly: Boolean(subInfo),
				precheck,
				submitSummary,
			});
		} else if (claimInfo) {
			stateCode = "IN_PROGRESS";
			stateLabel = "🟡 ĐANG XÂY DỰNG";
			activeBranch = claimInfo.branchName;
			relTime = claimInfo.relTime;
		}

		tasksReport.push({
			taskId: t.taskId,
			title: t.title,
			plotId: t.plotId,
			district: t.district,
			modulePath: t.modulePath,
			stateCode,
			stateLabel,
			activeBranch,
			relTime,
			precheck,
			submitSummary,
		});
	}

	return {
		scannedAt: new Date().toISOString(),
		masterBranch,
		workerBranchCount: workerBranches.length,
		pendingQaCount: pendingQaItems.length,
		pendingQaItems,
		workerBranches,
		tasks: tasksReport,
	};
}

// Chế độ chạy trực tiếp từ dòng lệnh: `node bridge/qa-radar.mjs`
if (import.meta.url === `file://${process.argv[1]}`) {
	const snap = computeRadarSnapshot({ doSyncFetch: true });
	console.log("================================================================================");
	console.log(
		`📡 TRẠM RADA NGHIỆM THU (${snap.scannedAt}) — Agent Phụ đang mở: ${snap.workerBranchCount} | Cần nghiệm thu: ${snap.pendingQaCount}`
	);
	console.log("================================================================================");
	if (snap.pendingQaCount > 0) {
		console.log("\n🔔 DANH SÁCH CẦN NGHIỆM THU NGAY:");
		for (const p of snap.pendingQaItems) {
			const pc = p.precheck;
			const pcTxt = pc
				? `${pc.lines} dòng Luau | Máu ẩn refs: ${pc.integrityMatches} | build(): ${pc.hasBuildFn ? "OK" : "THIẾU"} | File cấm bị chạm: ${pc.forbiddenTouched.length}`
				: "Chưa thấy file module trong đường dẫn chuẩn!";
			console.log(`  👉 [${p.taskId}] ${p.title} (${p.plotId}) — Nhánh: ${p.branchName} (${p.relTime})`);
			console.log(`     Pre-check: ${pcTxt}`);
			if (p.submitSummary) console.log(`     Ghi chú  : ${p.submitSummary}`);
		}
	}
	console.log("\n📋 TRẠNG THÁI 8 HẠNG MỤC TRÊN BẢN ĐỒ:");
	for (const t of snap.tasks) {
		const br = t.activeBranch ? ` [${t.activeBranch} • ${t.relTime}]` : "";
		console.log(`  • ${t.taskId.padEnd(28)} : ${t.stateLabel}${br}`);
	}
	if (snap.workerBranches.length > 0) {
		console.log("\n🌿 HOẠT ĐỘNG CÁC NHÁNH AGENT PHỤ:");
		for (const wb of snap.workerBranches) {
			console.log(`  - ${wb.branchName} (${wb.relTime}): "${wb.subject}" [${wb.shortSha}]`);
		}
	}
	console.log("================================================================================");
}
