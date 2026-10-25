#!/usr/bin/env node
import { loadExistingBundle, buildGitHubCommandBarOneLiner, GITHUB_OWNER, GITHUB_REPO, GITHUB_BRANCH } from "./compiler.mjs";

const bundle = loadExistingBundle();
console.log(JSON.stringify({
	repo: `${GITHUB_OWNER}/${GITHUB_REPO}`,
	branch: GITHUB_BRANCH,
	syncVersion: bundle.version,
	hash: bundle.hash,
	files: bundle.files || [],
	actionsCount: (bundle.actions || []).length,
	commandBarOneLiner: buildGitHubCommandBarOneLiner(),
}, null, 2));
