#!/usr/bin/env node
/**
 * bridge/qa-radar.mjs
 * TRẠM RADA QUÉT TỰ ĐỘNG CÁC AGENT PHỤ & PHÁT TÍN HIỆU NGHIỆM THU (REAL-TIME QA RADAR)
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
			const parts = line.split(/\s+/);
			const tabIdx = line.indexOf("\t");
			if (parts.length >= 3 && tabIdx !== -1) {
				masterModuleBlobs.set(line.slice(tabIdx + 1).trim(), parts[2]);
			}
		}
	}

	const refsRaw = gitSync([
		"for-each-ref",
		"--sort=-committerdate",
		"--format=%(refname:short)|%(committerdate:iso8601)|%(committerdate:relative)|%(contents:subject)|%(objectname:short)",
		"refs/remotes/origin/arena/",
	]);

	const workerBranches = [];
	const claimsByTask = new Map();
	const submitsByTask = new Map();
	const workerModulesByPath = new Map();
	const forbiddenSet = new Set(board.zeroConflictContract?.forbiddenSharedEdits || []);

	function pushMapArr(map, key, val) {
		if (!map.has(key)) map.set(key, []);
		map.get(key).push(val);
	}

	for (const row of refsRaw.split("\n").filter(Boolean)) {
		const [ref, isoDate, relTime, subject, shortSha] = row.split("|");
		const branchName = ref.replace(/^origin\//, "");
		const isMaster = branchName === masterBranch;
		if (isMaster) continue;

		const noteFiles = gitSync(["ls-tree", "--name-only", ref, `${NOTES_REL_DIR}/`]);
		const branchClaims = [];
		const branchSubmits = [];
		if (noteFiles) {
			for (const nf of noteFiles.split("\n").map((s) => s.trim()).filter(Boolean)) {
				const base = path.basename(nf, ".md");
				const cm = base.match(/^CLAIM_(.+)__([a-zA-Z0-9_-]+)$/);
				if (cm) {
					const content = gitSync(["show", `${ref}:${nf}`]);
					pushMapArr(claimsByTask, cm[1], { ref, branchName, relTime, shortSha, subject, notePath: nf, content });
					branchClaims.push(cm[1]);
				}
				const sm = base.match(/^SUBMIT_(.+)__([a-zA-Z0-9_-]+)$/);
				if (sm) {
					const content = gitSync(["show", `${ref}:${nf}`]);
					pushMapArr(submitsByTask, sm[1], { ref, branchName, relTime, shortSha, subject, notePath: nf, content });
					branchSubmits.push(sm[1]);
				}
			}
		}

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

				const src = gitSync(["show", `${ref}:${modPath}`]);
				const lines = src ? src.split("\n").length : 0;
				const integrityMatches = src ? (src.match(/integrity|brickWall|segmentedRow/g) || []).length : 0;
				const hasBuildFn = src ? /function\s+\w+\.build\s*\(/.test(src) || /build\s*=\s*function/.test(src) : false;

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
				pushMapArr(workerModulesByPath, modPath, { ref, branchName, relTime, shortSha, subject, precheck });
			}
		}

		workerBranches.push({
			ref,
			branchName,
			shortId: branchName.replace(/^arena\//, "").slice(0, 8),
			isoDate,
			relTime,
			subject,
			shortSha,
			claims: branchClaims,
			submits: branchSubmits,
			builtModules,
		});
	}

	const tasksReport = [];
	const pendingQaItems = [];

	for (const t of board.tasks) {
		const modList = workerModulesByPath.get(t.modulePath) || [];
		const subList = submitsByTask.get(t.taskId) || [];
		const claimList = claimsByTask.get(t.taskId) || [];

		const unintegratedMods = modList.filter((m) => !m.precheck.alreadyIntegrated);
		const integratedInMaster =
			t.status === "completed" ||
			(masterModuleBlobs.has(t.modulePath) && unintegratedMods.length === 0);

		let stateCode = "FREE";
		let stateLabel = "🟢 TRỐNG — Chờ nhận";
		let activeBranches = [];
		let relTime = "";
		let precheck = unintegratedMods[0]?.precheck || modList[0]?.precheck || null;
		let submitSummary = "";

		if (integratedInMaster) {
			stateCode = "INTEGRATED";
			stateLabel = "✅ ĐÃ LÊN STUDIO";
		} else if (subList.length > 0 || unintegratedMods.length > 0) {
			stateCode = subList.length > 0 ? "NEEDS_QA_SUBMITTED" : "NEEDS_QA_MODULE_PUSHED";
			stateLabel =
				subList.length > 0
					? "🔔 ĐÃ NỘP BÀI — CẦN NGHIỆM THU!"
					: "🟣 ĐÃ PUSH CODE — CẦN NGHIỆM THU!";
			const sources = subList.length > 0 ? subList : unintegratedMods;
			activeBranches = [...new Set(sources.map((s) => s.branchName))];
			relTime = sources[0].relTime;
			if (subList[0]) {
				submitSummary = subList[0].content
					.split("\n")
					.filter((l) => !l.startsWith("#"))
					.join(" ")
					.trim()
					.slice(0, 220);
			}
			for (const src of sources) {
				const matchMod = modList.find((m) => m.branchName === src.branchName)?.precheck || precheck;
				pendingQaItems.push({
					key: `${t.taskId}@${src.branchName}@${matchMod ? matchMod.blobSha.slice(0, 8) : src.shortSha}`,
					taskId: t.taskId,
					title: t.title,
					plotId: t.plotId,
					modulePath: t.modulePath,
					branchName: src.branchName,
					shortBranch: src.branchName.replace(/^arena\//, "").slice(0, 8),
					relTime: src.relTime,
					submittedExplicitly: subList.some((s) => s.branchName === src.branchName),
					precheck: matchMod,
					submitSummary,
				});
			}
		} else if (claimList.length > 0) {
			stateCode = "IN_PROGRESS";
			stateLabel = "🟡 ĐANG XÂY DỰNG";
			activeBranches = [...new Set(claimList.map((c) => c.branchName))];
			relTime = claimList[0].relTime;
		}

		tasksReport.push({
			taskId: t.taskId,
			title: t.title,
			plotId: t.plotId,
			district: t.district,
			modulePath: t.modulePath,
			stateCode,
			stateLabel,
			activeBranch: activeBranches.join(", ") || null,
			activeBranches,
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
				? `${pc.lines} dòng Luau | Máu ẩn refs: ${pc.integrityMatches} | build(): ${pc.hasBuildFn ? "OK" : "THIẾU"} | File cấm chạm: ${pc.forbiddenTouched.length}`
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
