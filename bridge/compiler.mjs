import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
export const REPO_ROOT = path.resolve(__dirname, "..");
export const PROJECT_FILE = path.join(REPO_ROOT, "default.project.json");
export const SYNC_BUNDLE_FILE = path.join(REPO_ROOT, "studio-sync.json");

export const GITHUB_OWNER = "khungdienchinhhieu-cmd";
export const GITHUB_REPO = "RobloxStudio-connecting";
export const GITHUB_BRANCH = "arena/b37b6115-robloxstudio-connecting";

const KNOWN_CONTAINER_CLASSES = {
	StarterPlayerScripts: "StarterPlayerScripts",
	StarterCharacterScripts: "StarterCharacterScripts",
};

export function classifyScriptFile(fileName) {
	if (/^init\.server\.luau?$/i.test(fileName)) {
		return { isInit: true, className: "Script", baseName: "init" };
	}
	if (/^init\.client\.luau?$/i.test(fileName)) {
		return { isInit: true, className: "LocalScript", baseName: "init" };
	}
	if (/^init\.luau?$/i.test(fileName)) {
		return { isInit: true, className: "ModuleScript", baseName: "init" };
	}
	let m = fileName.match(/^(.+)\.server\.luau?$/i);
	if (m) {
		return { isInit: false, className: "Script", baseName: m[1] };
	}
	m = fileName.match(/^(.+)\.client\.luau?$/i);
	if (m) {
		return { isInit: false, className: "LocalScript", baseName: m[1] };
	}
	m = fileName.match(/^(.+)\.luau?$/i);
	if (m) {
		return { isInit: false, className: "ModuleScript", baseName: m[1] };
	}
	return null;
}

function compileFsDirectory(absDir, relDir, fileManifest) {
	if (!fs.existsSync(absDir)) {
		return {
			className: "Folder",
			managed: true,
			children: {},
		};
	}

	const entries = fs
		.readdirSync(absDir, { withFileTypes: true })
		.sort((a, b) => a.name.localeCompare(b.name));

	let nodeClassName = "Folder";
	let nodeSource = undefined;
	let nodeRepoPath = undefined;
	const children = {};

	for (const entry of entries) {
		if (entry.name.startsWith(".")) continue;
		const fullPath = path.join(absDir, entry.name);
		const relPath = path.posix.join(relDir, entry.name);

		if (entry.isDirectory()) {
			children[entry.name] = compileFsDirectory(fullPath, relPath, fileManifest);
		} else if (entry.isFile()) {
			const info = classifyScriptFile(entry.name);
			if (!info) continue;

			const source = fs.readFileSync(fullPath, "utf8");
			fileManifest.push({
				repoPath: relPath,
				className: info.className,
				bytes: Buffer.byteLength(source, "utf8"),
			});

			if (info.isInit) {
				nodeClassName = info.className;
				nodeSource = source;
				nodeRepoPath = relPath;
			} else {
				children[info.baseName] = {
					className: info.className,
					managed: true,
					repoPath: relPath,
					source,
					children: {},
				};
			}
		}
	}

	const result = {
		className: nodeClassName,
		managed: true,
		children,
	};
	if (nodeSource !== undefined) {
		result.source = nodeSource;
		result.repoPath = nodeRepoPath;
	}
	return result;
}

function compileProjectNode(nodeName, spec, depth, fileManifest) {
	if (spec.$path) {
		const relPath = spec.$path.replace(/\\/g, "/");
		const absPath = path.resolve(REPO_ROOT, relPath);
		if (fs.existsSync(absPath) && fs.statSync(absPath).isFile()) {
			const info = classifyScriptFile(path.basename(absPath)) || { className: "ModuleScript" };
			const source = fs.readFileSync(absPath, "utf8");
			fileManifest.push({
				repoPath: relPath,
				className: info.className,
				bytes: Buffer.byteLength(source, "utf8"),
			});
			return {
				className: spec.$className || info.className,
				managed: true,
				repoPath: relPath,
				source,
				properties: spec.$properties || undefined,
				children: {},
			};
		}
		const compiled = compileFsDirectory(absPath, relPath, fileManifest);
		if (spec.$className) compiled.className = spec.$className;
		if (spec.$properties) compiled.properties = spec.$properties;
		return compiled;
	}

	const isService = depth === 1;
	const className =
		spec.$className ||
		(isService ? nodeName : KNOWN_CONTAINER_CLASSES[nodeName] || "Folder");

	const children = {};
	for (const [key, childSpec] of Object.entries(spec)) {
		if (key.startsWith("$")) continue;
		if (childSpec && typeof childSpec === "object") {
			children[key] = compileProjectNode(key, childSpec, depth + 1, fileManifest);
		}
	}

	return {
		className,
		isService,
		managed: false,
		properties: spec.$properties || undefined,
		children,
	};
}

export function loadExistingBundle() {
	if (!fs.existsSync(SYNC_BUNDLE_FILE)) {
		return { version: 0, hash: "", actions: [] };
	}
	try {
		return JSON.parse(fs.readFileSync(SYNC_BUNDLE_FILE, "utf8"));
	} catch {
		return { version: 0, hash: "", actions: [] };
	}
}

export function compileSyncBundle(extraAction = null) {
	const rawProject = JSON.parse(fs.readFileSync(PROJECT_FILE, "utf8"));
	const tree = rawProject.tree || {};
	const fileManifest = [];
	const services = {};

	for (const [key, spec] of Object.entries(tree)) {
		if (key.startsWith("$")) continue;
		if (spec && typeof spec === "object") {
			services[key] = compileProjectNode(key, spec, 1, fileManifest);
		}
	}

	const prev = loadExistingBundle();
	const actions = Array.isArray(prev.actions) ? [...prev.actions] : [];
	if (extraAction) {
		actions.push(extraAction);
		if (actions.length > 50) {
			actions.splice(0, actions.length - 50);
		}
	}

	const contentHash = crypto
		.createHash("sha256")
		.update(JSON.stringify({ projectName: rawProject.name, services, actions }))
		.digest("hex")
		.slice(0, 16);

	const nextVersion = contentHash === prev.hash ? prev.version || 1 : (prev.version || 0) + 1;

	return {
		version: nextVersion,
		hash: contentHash,
		projectName: rawProject.name || GITHUB_REPO,
		repo: `${GITHUB_OWNER}/${GITHUB_REPO}`,
		branch: GITHUB_BRANCH,
		updatedAt: new Date().toISOString(),
		files: fileManifest,
		services,
		actions,
	};
}

export function buildGitHubCommandBarOneLiner() {
	const encodedRef = encodeURIComponent(GITHUB_BRANCH);
	const apiUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/plugin/StudioLiveBridge.server.luau?ref=${encodedRef}`;
	return `local h=game:GetService("HttpService") h.HttpEnabled=true loadstring(h:RequestAsync({Url="${apiUrl}",Method="GET",Headers={Accept="application/vnd.github.raw+json"}}).Body)()`;
}
