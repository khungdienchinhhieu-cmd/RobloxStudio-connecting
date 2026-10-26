/**
 * Kiểm tra KHỐI ĐÈ NHAU (interpenetration) giữa các part của một công trình.
 *
 *   node tools/building_sim/overlap_check.cjs                 # tất cả module
 *   node tools/building_sim/overlap_check.cjs Plot_E1_...     # một module
 *
 * Dựng công trình thật trong Luau VM, lấy AABB có xoay (OBB → AABB bảo thủ), rồi
 * tìm các cặp part chồng nhau. Bỏ qua các cặp "được phép" để không báo rác:
 *   • một trong hai là part trang trí (CanCollide = false khi build — sàn/rug/kính
 *     con, ghế con, đèn…), vì chúng cố tình nằm trong vật khác;
 *   • chồng ít (< --min thể tích, mặc định 6 stud³) — chạm mép / khớp nối;
 *   • cùng nhóm chức năng (group) — ví dụ các nan cửa cuốn nằm sát nhau.
 * In ra 15 cặp tệ nhất kèm thể tích chồng, thoát code 1 nếu vượt ngưỡng.
 *
 * Mục đích: bắt lỗi "bàn ăn đè lên cầu thang" trước khi publish.
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

const STRUCT = /wall|slab|floor|roof|deck|tile|beam|mullion|lintel|header|band|trim|curb|stripe|seam|ring|rib|rail|pane|cap|joist|girder|column|pier|canopy|awning/i;
const argv = process.argv.slice(2);
const minVol = Number((argv.find((a) => a.startsWith("--min=")) || "--min=6").split("=")[1]);
const only = argv.filter((a) => !a.startsWith("--"));

(async () => {
  const modulesDir = path.join(REPO, "src/shared/World/Modules");
  let files = fs.readdirSync(modulesDir).filter((f) => f.endsWith(".luau") && f !== "RegistryHealthcheck.luau");
  if (only.length) files = files.filter((f) => only.some((o) => f.includes(o)));

  const prelude = read(path.join(__dirname, "prelude.luau"));
  const wg = patchRet(read(path.join(REPO, "src/shared/WorldGrid.luau")), "WorldGrid", "WORLDGRID");
  const pb = patchRet(read(path.join(REPO, "src/shared/World/PartBuilder.luau")), "PartBuilder", "PARTBUILDER");
  const bkRaw = read(path.join(REPO, "src/shared/World/BuildKit.luau"));
  const bk = patchRequires(bkRaw.slice(0, bkRaw.lastIndexOf("return BuildKit"))) + "BUILDKIT = BuildKit";

  let totalBad = 0;
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
		local hx, hy, hz = s.X * 0.5, s.Y * 0.5, s.Z * 0.5
		local e = {
			math.abs(R[1]) * hx + math.abs(R[2]) * hy + math.abs(R[3]) * hz,
			math.abs(R[4]) * hx + math.abs(R[5]) * hy + math.abs(R[6]) * hz,
			math.abs(R[7]) * hx + math.abs(R[8]) * hy + math.abs(R[9]) * hz,
		}
		local g = "?"
		local par = p.Parent
		if par and par.Parent then g = tostring(par.Name) end
		OUT[#OUT + 1] = string.format("%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%d,%s,%s",
			cf.P.X, cf.P.Y, cf.P.Z, e[1], e[2], e[3], (p.CanCollide == false) and 0 or 1, p.Name or "?", g)
	end
	RUN[1] = tostring(#PARTS)
end)
RAW = tostring(ok) .. "|" .. tostring(err) .. "|" .. table.concat(OUT, ";")
`;
    let out;
    try {
      out = await lua.execute(
        prelude + "\nOUT = {}\nRUN = {}\n" + wg + "\n" + pb + "\n" + bk + "\n" + mod + "\n" + driver + "\nreturn RAW\n"
      );
    } catch (e) {
      console.log(`❌ ${f} lỗi nạp: ${String(e.message).slice(0, 200)}`);
      totalBad++;
      continue;
    }
    const text = Array.isArray(out) ? out[0] : out;
    const [ok, err, rows] = String(text).split("|");
    if (ok !== "true") {
      console.log(`❌ ${f} build lỗi: ${err}`);
      totalBad++;
      continue;
    }
    const boxes = [];
    for (const row of (rows || "").split(";")) {
      if (!row) continue;
      const [x, y, z, ex, ey, ez, coll, name, group] = row.split(",");
      boxes.push({ x: +x, y: +y, z: +z, ex: +ex, ey: +ey, ez: +ez, coll: coll === "1", name, group });
    }
    // lập chỉ mục theo trục X để không phải so O(n²) toàn bộ
    let worst = [];
    for (let i = 0; i < boxes.length; i++) {
      const a = boxes[i];
      for (let j = i + 1; j < boxes.length; j++) {
        const b = boxes[j];
        if (!a.coll || !b.coll) continue; // part trang trí: bỏ qua
        if (a.group === b.group) continue; // cùng nhóm (nan cửa, bậc thang…): bỏ qua
        // kết cấu gặp kết cấu (tường × sàn × mái) là bình thường: bỏ qua
        if (STRUCT.test(a.name) && STRUCT.test(b.name)) continue;
        const ox = a.ex + b.ex - Math.abs(a.x - b.x);
        if (ox <= 0.05) continue;
        const oy = a.ey + b.ey - Math.abs(a.y - b.y);
        if (oy <= 0.05) continue;
        const oz = a.ez + b.ez - Math.abs(a.z - b.z);
        if (oz <= 0.05) continue;
        const vol = ox * oy * oz;
        if (vol < minVol) continue;
        // tấm mỏng (sàn/mái/bệ) cắm xuyên qua vật khác theo phương đứng: bình thường
        const thinEmbed = (p, q2) => p.ey <= 1.6 && p.ex * p.ez >= 150 &&
          Math.abs(p.y - q2.y) + p.ey <= q2.ey + 0.01;
        if (thinEmbed(a, b) || thinEmbed(b, a)) continue;
        worst.push({ a: a.name, b: b.name, vol, at: [a.x, a.y, a.z] });
      }
    }
    worst.sort((p, q) => q.vol - p.vol);
    const n = worst.length;
    const tag = n === 0 ? "✅" : "⚠️";
    console.log(`${tag} ${f.padEnd(40)} ${String(boxes.length).padStart(5)} khối · ${n} cặp đè > ${minVol} stud³`);
    for (const w of worst.slice(0, 8)) {
      console.log(`     ${w.vol.toFixed(1).padStart(8)} stud³  ${w.a} ✕ ${w.b}   @ (${w.at[0].toFixed(0)}, ${w.at[1].toFixed(0)}, ${w.at[2].toFixed(0)})`);
    }
    totalBad += n;
  }
  console.log(totalBad === 0 ? "\n✅ Không có khối nào đè nhau quá ngưỡng." : `\n⚠️ Tổng ${totalBad} cặp đè nhau cần xem lại.`);
})();
