/**
 * Xuất toạ độ/kích thước/màu của mọi part trong một công trình ra JSON để vẽ QA.
 *
 *   node tools/building_sim/dump_parts.cjs Plot_E1_PacificBluffsVilla > /tmp/p.json
 *
 * JSON: { plot, ok, parts: [{ n:name, x,y,z, ex,ey,ez, r:[9 số ma trận xoay], c:"r,g,b", m:material }] }
 */
const fs = require("fs");
const path = require("path");
let Lua;
try {
  ({ Lua } = require("@luau-rs/luau"));
} catch (e) {
  ({ Lua } = require("/tmp/luau-check/node_modules/@luau-rs/luau"));
}
const REPO = path.resolve(__dirname, "..", "..");
const read = (p) => fs.readFileSync(p, "utf8");

function patchRequires(src) {
  const map = { WorldGrid: "WORLDGRID", PartBuilder: "PARTBUILDER", BuildKit: "BUILDKIT" };
  let out = src;
  for (const [modName, globalName] of Object.entries(map)) {
    out = out.replace(
      new RegExp(`local\\s+(\\w+)\\s*=\\s*require\\([^\\n]*WaitForChild\\("${modName}"\\)\\)`),
      `local $1 = ${globalName}`
    );
  }
  for (const modName of Object.keys(map)) {
    if (new RegExp(`WaitForChild\\("${modName}"\\)`).test(out)) throw new Error(`chưa thay được require ${modName}`);
  }
  return out;
}
function patchRet(src, name, g) {
  const i = src.lastIndexOf("return " + name);
  if (i < 0) throw new Error("không thấy `return " + name + "`");
  return src.slice(0, i) + g + " = " + name + src.slice(i + ("return " + name).length);
}

(async () => {
  const modulesDir = path.join(REPO, "src/shared/World/Modules");
  let files = fs.readdirSync(modulesDir).filter((f) => f.endsWith(".luau") && f !== "RegistryHealthcheck.luau");
  const only = process.argv.slice(2).filter((a) => !a.startsWith("--"));
  if (only.length) files = only.map((o) => (o.endsWith(".luau") ? o : (o.startsWith("Plot_") ? `${o}.luau` : `Plot_${o}.luau`)));

  const prelude = read(path.join(__dirname, "prelude.luau"));
  const wg = patchRet(read(path.join(REPO, "src/shared/WorldGrid.luau")), "WorldGrid", "WORLDGRID");
  const pb = patchRet(read(path.join(REPO, "src/shared/World/PartBuilder.luau")), "PartBuilder", "PARTBUILDER");
  const bkRaw = read(path.join(REPO, "src/shared/World/BuildKit.luau"));
  const bk = patchRequires(bkRaw.slice(0, bkRaw.lastIndexOf("return BuildKit"))) + "BUILDKIT = BuildKit";

  const out = {};
  for (const f of files) {
    const lua = await Lua.create();
    const mod = patchRet(patchRequires(read(path.join(modulesDir, f))), "Module", "MODULE");
    const driver = `
local ok, err = pcall(function()
	local c = Instance.new("Folder")
	MODULE.build(c)
	for _, p in ipairs(PARTS) do
		local s, cf = p.Size, p.CFrame
		local R = cf.R
		local col = p.Color
		OUT[#OUT + 1] = string.format("%s|%.2f,%.2f,%.2f|%.2f,%.2f,%.2f|%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f|%d,%d,%d",
			p.Name or "?",
			cf.P.X, cf.P.Y, cf.P.Z,
			s.X, s.Y, s.Z,
			R[1], R[2], R[3], R[4], R[5], R[6], R[7], R[8], R[9],
			math.floor((col.R or 0.64) * 255), math.floor((col.G or 0.64) * 255), math.floor((col.B or 0.64) * 255))
	end
	RUN[1] = tostring(MODULE.PlotId) .. "|" .. tostring(#PARTS)
end)
RAW = tostring(ok) .. "|" .. tostring(err) .. "|" .. tostring(RUN[1]) .. "#" .. table.concat(OUT, ";")
`;
    let res;
    try {
      res = await lua.execute(
        prelude + "\nOUT = {}\nRUN = {}\n" + wg + "\n" + pb + "\n" + bk + "\n" + mod + "\n" + driver + "\nreturn RAW\n"
      );
    } catch (e) {
      console.error(`❌ ${f}: ${String(e.message).slice(0, 200)}`);
      continue;
    }
    const text = String(Array.isArray(res) ? res[0] : res);
    const i1 = text.indexOf("|");
    const i2 = text.indexOf("|", i1 + 1);
    const ok = text.slice(0, i1);
    const err = text.slice(i1 + 1, i2);
    const rest = text.slice(i2 + 1);
    if (ok !== "true") {
      console.error(`❌ ${f} build: ${err}`);
      continue;
    }
    const hash = rest.indexOf("#");
    const head = rest.slice(0, hash);
    const [plotId] = head.split("|");
    const rows = rest.slice(hash + 1);
    const parts = [];
    for (const row of rows.split(";")) {
      if (!row) continue;
      const [n, pos, size, rot, c] = row.split("|");
      const [x, y, z] = pos.split(",").map(Number);
      const [ex, ey, ez] = size.split(",").map(Number);
      const r = rot.split(",").map(Number);
      const [cr, cg, cb] = c.split(",").map(Number);
      parts.push({ n, x, y, z, ex, ey, ez, r, c: [cr, cg, cb] });
    }
    out[f.replace(/\.luau$/, "")] = { plotId, parts };
    console.error(`  ${f.padEnd(38)} ${String(parts.length).padStart(5)} part`);
  }
  process.stdout.write(JSON.stringify(out));
})();
