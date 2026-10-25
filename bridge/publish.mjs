#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import {
	REPO_ROOT,
	SYNC_BUNDLE_FILE,
	GITHUB_BRANCH,
	compileSyncBundle,
	buildGitHubCommandBarOneLiner,
} from "./compiler.mjs";

function parseArgs(argv) {
	let message = "chore: cập nhật đồng bộ Roblox Studio (Rojo + Bridge)";
	let actionDesc = null;
	let actionCode = null;
	let actionFile = null;

	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		if (arg === "--action-desc" && argv[i + 1]) {
			actionDesc = argv[++i];
		} else if (arg === "--action-code" && argv[i + 1]) {
			actionCode = argv[++i];
		} else if (arg === "--action-file" && argv[i + 1]) {
			actionFile = argv[++i];
		} else if (!arg.startsWith("--")) {
			message = arg;
		}
	}

	if (actionFile && !actionCode) {
		actionCode = fs.readFileSync(path.resolve(REPO_ROOT, actionFile), "utf8");
	}

	let extraAction = null;
	if (actionCode) {
		extraAction = {
			id: `act-${Date.now()}`,
			description: actionDesc || "Tác vụ trực tiếp từ Arena AI",
			code: actionCode,
			createdAt: new Date().toISOString(),
		};
	}

	return { message, extraAction };
}

function runGit(args) {
	return execFileSync("git", args, { cwd: REPO_ROOT, encoding: "utf8" }).trim();
}

async function main() {
	const { message, extraAction } = parseArgs(process.argv.slice(2));
	const bundle = compileSyncBundle(extraAction);
	fs.writeFileSync(SYNC_BUNDLE_FILE, JSON.stringify(bundle, null, 2) + "\n", "utf8");

	runGit(["add", "-A"]);
	const status = runGit(["status", "--porcelain"]);
	if (status) {
		runGit(["commit", "-m", message]);
	}
	runGit(["push", "-u", "origin", GITHUB_BRANCH]);

	const fullSha = runGit(["rev-parse", "HEAD"]);
	const headSha = fullSha.slice(0, 7);
	console.log(`✅ Đã đồng bộ lên GitHub (${GITHUB_BRANCH} @ ${headSha}) — Sync v${bundle.version}`);
	console.log(`📁 Số file Rojo: ${bundle.files.length} | Tác vụ Studio: ${bundle.actions.length}`);
	console.log(`🔗 Lệnh Command Bar:\n${buildGitHubCommandBarOneLiner(fullSha)}`);
}

main().catch((err) => {
	console.error("[Publish Error]", err.message);
	process.exit(1);
});
