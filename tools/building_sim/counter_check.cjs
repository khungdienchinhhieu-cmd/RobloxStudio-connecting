/**
 * Kiểm tra chỗ đặt QUẦY DỊCH VỤ có thực sự trống không.
 *
 *   node tools/building_sim/counter_check.cjs
 *
 * Nạp TẤT CẢ module đã dựng (src/shared/World/Modules/*.luau), dựng bằng Luau VM,
 * rồi với từng quầy trong BuildingServices.luau (chỉ quầy ở ô ĐÃ có công trình):
 *   • tính toạ độ thật = plot.center + offset (đúng công thức BuildingServices.worldPosition)
 *   • kiểm tra một cột trụ đứng cao 3 stud, bán kính `--radius` (mặc định 3) quanh quầy
 *     có bị khối nào của công trình chắn không (chồng AABB có xoay thật)
 *   • báo cáo quầy nào bị chôn trong tường / nằm trên mái / lơ lửng ngoài sân
 *
 * Thoát code 1 nếu có quầy bị chắn.
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
const SOLVE = process.argv.includes("--solve");

// Plot centers — phải khớp WorldGrid.PLOTS (nguồn duy nhất bên Luau)
const PLOT_CENTER = {
  Plot_C1: [-226, 58], Plot_C2: [0, 58], Plot_C3_West: [226, 58], Plot_C3_East: [226, 58],
  Plot_D1: [-226, -132], Plot_D2: [0, -132], Plot_D3: [226, -132],
  Plot_E1: [-447, -132], Plot_E2: [447, -132], Plot_E3: [-447, 58], Plot_E4: [447, 58],
};
const ALIAS = { Plot_C1: "C1", Plot_C2: "C2", Plot_C3_West: "C3", Plot_C3_East: "C3", Plot_D1: "D1", Plot_D2: "D2", Plot_D3: "D3", Plot_E1: "E1", Plot_E2: "E2", Plot_E3: "E3", Plot_E4: "E4" };
const PLOT_BOX = {
  E1: [-536, -358, -204, -60], D1: [-318, -134, -204, -60], D2: [-86, 86, -204, -60], D3: [134, 318, -204, -60], E2: [358, 536, -204, -60],
  E3: [-536, -358, -12, 128], C1: [-318, -134, -12, 128], C2: [-86, 86, -12, 128], C3: [134, 318, -12, 128], E4: [358, 536, -12, 128],
};

function patchRet(src, name, g) {
  const i = src.lastIndexOf("return " + name);
  if (i < 0) throw new Error("không thấy `return " + name + "`");
  return src.slice(0, i) + g + " = " + name + src.slice(i + ("return " + name).length);
}

function parseServices(src) {
  const re = /id = "(\w+)",\s*\n\s*plotId = "(\w+)",\s*\n\s*title = "([^"]*)",\s*\n\s*subtitle = "([^"]*)",\s*\n\s*icon = "([^"]*)",\s*\n\s*kind = "(\w+)",\s*\n\s*price = (\d+),\s*\n\s*prompt = "([^"]*)",\s*\n\s*offset = Vector3\.new\(([-\d.]+), [-\d.]+, ([-\d.]+)\)/g;
  const out = [];
  let m;
  while ((m = re.exec(src)) !== null) {
    out.push({ id: m[1], plotId: m[2], title: m[3], kind: m[6], ox: Number(m[9]), oz: Number(m[10]) });
  }
  return out;
}

(async () => {
  const modulesDir = path.join(REPO, "src/shared/World/Modules");
  const modFiles = fs.readdirSync(modulesDir).filter((f) => f.endsWith(".luau") && f !== "RegistryHealthcheck.luau");
  const prelude = read(path.join(__dirname, "prelude.luau"));
  const wg = patchRet(read(path.join(REPO, "src/shared/WorldGrid.luau")), "WorldGrid", "WORLDGRID");
  const pb = patchRet(read(path.join(REPO, "src/shared/World/PartBuilder.luau")), "PartBuilder", "PARTBUILDER");
  const services = parseServices(read(path.join(REPO, "src/shared/World/BuildingServices.luau")));

  const builtPlots = new Set();
  const boxesByPlot = {};

  for (const f of modFiles) {
    const lua = await Lua.create();
    let mod = read(path.join(modulesDir, f));
    mod = mod.replace(/local\s+(\w+)\s*=\s*require\(Shared:WaitForChild\("WorldGrid"\)\)/, "local $1 = WORLDGRID");
    mod = mod.replace(/local\s+(\w+)\s*=\s*require\(.*WaitForChild\("PartBuilder"\)\)/, "local $1 = PARTBUILDER");
    mod = patchRet(mod, "Module", "MODULE");
    const driver = `
local ok, err = pcall(function()
	local c = Instance.new("Folder")
	local root = MODULE.build(c)
	for _, p in ipairs(PARTS) do
		local s, cf = p.Size, p.CFrame
		local R = cf.R
		local hx, hy, hz = s.X * 0.5, s.Y * 0.5, s.Z * 0.5
		local e = {
			math.abs(R[1]) * hx + math.abs(R[2]) * hy + math.abs(R[3]) * hz,
			math.abs(R[4]) * hx + math.abs(R[5]) * hy + math.abs(R[6]) * hz,
			math.abs(R[7]) * hx + math.abs(R[8]) * hy + math.abs(R[9]) * hz,
		}
		OUT[#OUT + 1] = string.format("%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%s", cf.P.X, cf.P.Y, cf.P.Z, e[1], e[2], e[3], p.Name or "?")
	end
	RUN[1] = tostring(MODULE.PlotId)
end)
RAW = RUN[1] .. "|" .. tostring(ok) .. "|" .. tostring(err) .. "|" .. table.concat(OUT, ";")
`;
    let out;
    try {
      out = await lua.execute(prelude + "\nOUT = {}\nRUN = {}\n" + wg + "\n" + pb + "\n" + mod + "\n" + driver + "\nreturn RAW\n");
    } catch (e) {
      console.log(`❌ ${f} lỗi nạp: ${String(e.message).slice(0, 200)}`);
      continue;
    }
    const text = Array.isArray(out) ? out[0] : out;
    const [plotId, ok, err, parts] = String(text).split("|");
    if (ok !== "true") { console.log(`❌ ${f} build lỗi: ${err}`); continue; }
    builtPlots.add(plotId);
    const boxes = [];
    for (const row of (parts || "").split(";")) {
      if (!row) continue;
      const [x, y, z, ex, ey, ez, name] = row.split(",");
      boxes.push({ x: +x, y: +y, z: +z, ex: +ex, ey: +ey, ez: +ez, name });
    }
    boxesByPlot[plotId] = boxes;
    console.log(`  nạp ${plotId.padEnd(16)} ${String(boxes.length).padStart(5)} khối  (${f})`);
  }

  console.log("\n── QUẦY DỊCH VỤ: CHỖ ĐẶT CÓ TRỐNG KHÔNG ───────────────────────────");
  const CY0 = 1.15, CY1 = 4.15; // cột kiểm tra 3 stud trên mặt vỉa hè
  const R = 4.0; // bán kính đế quầy (7.9 stud) + 0.05 dư — không được chạm tường
  let bad = 0;
  let checked = 0;
  for (const s of services) {
    if (!builtPlots.has(s.plotId)) continue;
    checked++;
    const c = PLOT_CENTER[s.plotId];
    if (!c) { console.log(`  ⚠ ${s.id}: không biết tâm ô ${s.plotId}`); bad++; continue; }
    const x = c[0] + s.ox;
    const z = c[1] + s.oz;
    const boxes = boxesByPlot[s.plotId] || [];
    // Vật cản = khối nhô lên khỏi mặt đi (top > CY0 + 0.35) và còn nằm trong tầm người.
    // Sàn / slab / paver (top thấp) KHÔNG tính là vật cản — đó là mặt đứng lên.
    const hits = [];
    let groundTop = 0;
    for (const b of boxes) {
      const top = b.y + b.ey;
      const bot = b.y - b.ey;
      const dx = Math.max(0, Math.abs(b.x - x) - b.ex);
      const dz = Math.max(0, Math.abs(b.z - z) - b.ez);
      const d2 = dx * dx + dz * dz;
      if (d2 < 1.2 * 1.2 && top <= CY0 + 2.2) groundTop = Math.max(groundTop, top); // mặt đỡ dưới chân
      if (bot > CY1 || top < CY0 + 0.35) continue;                                // quá cao hoặc là sàn
      if (d2 < R * R) {
        hits.push({ name: b.name, deep: dx === 0 && dz === 0, d: Math.sqrt(d2) });
      }
    }
    const alias = ALIAS[s.plotId];
    const box = PLOT_BOX[alias];
    const inside = box && x > box[0] && x < box[1] && z > box[2] && z < box[3];
    if (SOLVE) {
      // Tìm chỗ trống gần nhất quanh anchor: lưới 0.5 stud, ưu tiên gần anchor.
      let best = null;
      for (let r = 0; r <= 12 && !best; r += 0.5) {
        for (let a = 0; a < 64; a++) {
          const ang = (a / 64) * Math.PI * 2;
          // bám lưới 0,5 stud để toạ độ in ra == toạ độ dùng thật (không lệch do làm tròn)
          const px = Math.round((x + Math.cos(ang) * r) * 2) / 2;
          const pz = Math.round((z + Math.sin(ang) * r) * 2) / 2;
          if (!box || !(px > box[0] + 4 && px < box[1] - 4 && pz > box[2] + 4 && pz < box[3] - 4)) continue;
          let ok = true, floorTop = 0;
          for (const b of boxes) {
            const top = b.y + b.ey, bot = b.y - b.ey;
            const dx = Math.max(0, Math.abs(b.x - px) - b.ex);
            const dz = Math.max(0, Math.abs(b.z - pz) - b.ez);
            const d2 = dx * dx + dz * dz;
            if (d2 < 1.4 * 1.4 && top <= CY0 + 2.2 && top > floorTop) floorTop = top;
            if (bot > CY1 || top < CY0 + 0.35) continue;
            if (d2 < R * R) { ok = false; break; }
          }
          if (!ok || floorTop < 1.0 || floorTop > 2.2) continue;
          best = { px, pz, floorTop };
          break;
        }
      }
      if (best) {
        console.log(`  ✔ ${s.id.padEnd(13)} offset = Vector3.new(${(best.px - c[0]).toFixed(1)}, 0, ${(best.pz - c[1]).toFixed(1)})   → (${best.px.toFixed(1)}, ${best.pz.toFixed(1)}) nền Y=${best.floorTop.toFixed(2)}`);
      } else {
        console.log(`  ✖ ${s.id.padEnd(13)} KHÔNG tìm được chỗ trống trong 12 stud quanh (${x.toFixed(1)}, ${z.toFixed(1)})`);
      }
      continue;
    }
    const tag = hits.length === 0 && inside ? "✅" : "❌";
    if (hits.length || !inside) bad++;
    console.log(
      `  ${tag} ${s.id.padEnd(13)} → (${x.toFixed(1)}, ${z.toFixed(1)})` +
      (inside ? "" : "  ⚠ NGOÀI Ô ĐẤT") +
      (hits.length ? `  ⚠ vướng ${hits.length} khối: ` + hits.slice(0, 4).map((h) => `${h.name}${h.deep ? "(đè)" : ""}`).join(", ") : "  trống") +
      (groundTop > 0 ? `  · mặt đỡ Y=${groundTop.toFixed(2)}` : "  · không có mặt đỡ")
    );
  }
  console.log(`\n  Đã kiểm ${checked}/${services.length} quầy (ô đã dựng: ${[...builtPlots].sort().join(" · ")})`);
  if (bad) { console.log(`\n❌ ${bad} quầy có vấn đề.`); process.exit(1); }
  console.log("\n✅ Mọi quầy đều nằm trong ô đất và không bị khối nào chắn.");
})();
