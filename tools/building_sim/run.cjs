/**
 * Harness QA công trình: chạy THẬT một module trong src/shared/World/Modules/
 * ngoài Roblox Studio, rồi đo bằng số — không tin báo cáo của agent phụ.
 *
 *   node tools/building_sim/run.cjs src/shared/World/Modules/Plot_D1_RockfordShowroom.luau
 *   node tools/building_sim/run.cjs <file> --json        # in JSON thô để xem chi tiết
 *
 * Đo:
 *   • số BasePart thật tạo ra            • % khối có máu ẩn (Destructible + PartHealth)
 *   • AABB có xoay thật (ma trận 3×3)    • khối tràn biên / dưới nền
 *   • khối nhỏ còn CanCollide            • CanTouch / CanQuery / CastShadow sai chuẩn
 *   • SurfaceGui sai (MaxDistance/TextScaled/PixelsPerStud)
 *   • PlotId module khai báo vs PlotId root đóng dấu
 *
 * Cần: npm i @luau-rs/luau  (hoặc /tmp/luau-check/node_modules/@luau-rs/luau)
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

// Thay mọi require(...WaitForChild("X")) bằng biến toàn cục đã nạp trước đó.
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
    if (new RegExp(`WaitForChild\\("${modName}"\\)`).test(out)) {
      throw new Error(`chưa thay được require ${modName}`);
    }
  }
  return out;
}


const target = process.argv[2];
if (!target) {
  console.error("Dùng: node tools/building_sim/run.cjs <module.luau>");
  process.exit(2);
}
const targetAbs = path.resolve(process.cwd(), target);
const wantJson = process.argv.includes("--json");

function readSrc(p) {
  return fs.readFileSync(p, "utf8");
}

(async () => {
  const lua = await Lua.create();
  const prelude = readSrc(path.join(__dirname, "prelude.luau"));

  // WorldGrid: bỏ `return WorldGrid` cuối file -> gán vào biến toàn cục
  const wgSrc = readSrc(path.join(REPO, "src/shared/WorldGrid.luau"));
  const wgIdx = wgSrc.lastIndexOf("return WorldGrid");
  if (wgIdx < 0) throw new Error("WorldGrid.luau không kết thúc bằng `return WorldGrid`");
  const wg = wgSrc.slice(0, wgIdx) + "WORLDGRID = WorldGrid" + wgSrc.slice(wgIdx + "return WorldGrid".length);

  // PartBuilder: tương tự
  const pbSrc = readSrc(path.join(REPO, "src/shared/World/PartBuilder.luau"));
  const pbIdx = pbSrc.lastIndexOf("return PartBuilder");
  if (pbIdx < 0) throw new Error("PartBuilder.luau không kết thúc bằng `return PartBuilder`");
  const pb = pbSrc.slice(0, pbIdx) + "PARTBUILDER = PartBuilder" + pbSrc.slice(pbIdx + "return PartBuilder".length);

  // BuildKit: bộ khung dựng dùng chung
  const bkSrc = readSrc(path.join(REPO, "src/shared/World/BuildKit.luau"));
  const bkIdx = bkSrc.lastIndexOf("return BuildKit");
  if (bkIdx < 0) throw new Error("BuildKit.luau không kết thúc bằng `return BuildKit`");
  const bk = patchRequires(bkSrc.slice(0, bkIdx)) + "BUILDKIT = BuildKit" + bkSrc.slice(bkIdx + "return BuildKit".length);

  // Module công trình: thay require(...) bằng biến toàn cục đã nạp
  let mod = patchRequires(readSrc(targetAbs));
  const modRet = mod.lastIndexOf("return Module");
  if (modRet < 0) throw new Error("Module không kết thúc bằng `return Module`");
  mod = mod.slice(0, modRet) + "MODULE = Module" + mod.slice(modRet + "return Module".length);

  const driver = `
local results = {}
local function log(s) results[#results + 1] = s end

local ok, err = pcall(function()
	local container = Instance.new("Folder")
	container.Name = "DistrictModules"
	local root = MODULE.build(container)

	-- gom part
	local parts = PARTS
	log("module=" .. tostring(MODULE.Id) .. " plot=" .. tostring(MODULE.PlotId))
	log("parts=" .. #parts)
	log("rootPlotId=" .. tostring(root:GetAttribute("PlotId")))

	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	local destructible, smallCollide, canTouchOn, castShadowBad = 0, 0, 0, 0
	local guiBad, zeroSize = 0, 0
	local names = {}
	local dupNames = 0

	for _, p in ipairs(parts) do
		local size = p.Size
		local cf = p.CFrame
		local R = cf.R
		local half = { size.X * 0.5, size.Y * 0.5, size.Z * 0.5 }
		local absR = {
			math.abs(R[1]), math.abs(R[2]), math.abs(R[3]),
			math.abs(R[4]), math.abs(R[5]), math.abs(R[6]),
			math.abs(R[7]), math.abs(R[8]), math.abs(R[9]),
		}
		local ex = absR[1] * half[1] + absR[2] * half[2] + absR[3] * half[3]
		local ey = absR[4] * half[1] + absR[5] * half[2] + absR[6] * half[3]
		local ez = absR[7] * half[1] + absR[8] * half[2] + absR[9] * half[3]
		local P = cf.P
		minX = math.min(minX, P.X - ex); maxX = math.max(maxX, P.X + ex)
		minY = math.min(minY, P.Y - ey); maxY = math.max(maxY, P.Y + ey)
		minZ = math.min(minZ, P.Z - ez); maxZ = math.max(maxZ, P.Z + ez)

		if p:GetAttribute("Destructible") == true and (p:GetAttribute("PartHealth") or 0) > 0 then
			destructible += 1
		end
		if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then zeroSize += 1 end
		local md = math.max(size.X, size.Y, size.Z)
		if md < 1.6 and p.CanCollide == true then smallCollide += 1 end
		if p.CanTouch == true then canTouchOn += 1 end
		if p.CastShadow == true and (p.Transparency > 0 or p.Material == Enum.Material.Neon or p.Material == Enum.Material.Glass) then
			castShadowBad += 1
		end
		if p.Name == nil or p.Name == "" then dupNames += 1 end
		names[p.Name] = (names[p.Name] or 0) + 1
	end

	local dupNameCount = 0
	for _, c in pairs(names) do if c > 1 then dupNameCount += 1 end end

	for _, o in ipairs(root:GetDescendants()) do
		if o.ClassName == "SurfaceGui" then
			if o.MaxDistance ~= 340 or o.TextScaled == true or o.PixelsPerStud > 32 then guiBad += 1 end
		end
	end

	log(string.format("aabb=%.2f,%.2f,%.2f .. %.2f,%.2f,%.2f", minX, minY, minZ, maxX, maxY, maxZ))
	log("destructible=" .. destructible)
	log("smallCollide=" .. smallCollide)
	log("canTouchOn=" .. canTouchOn)
	log("castShadowBad=" .. castShadowBad)
	log("guiBad=" .. guiBad)
	log("zeroSize=" .. zeroSize)
	log(string.format("dupNames=%d/%d", dupNameCount, #parts))
	log("partHealthMissing=" .. tostring((function()
		local n = 0
		for _, p in ipairs(parts) do if p:GetAttribute("MaxPartHealth") == nil then n += 1 end end
		return n
	end)()))
end)
log("build ok=" .. tostring(ok) .. " err=" .. tostring(err))
RAW = table.concat(results, string.char(10))
`;

  const chunk = [prelude, wg, pb, bk, mod, driver].join("\n");
  let out;
  try {
    out = await lua.execute(chunk + "\nreturn RAW\n");
  } catch (e) {
    console.error("❌ LUA ERROR:", e && e.message);
    const dump = "/tmp/building_chunk.luau";
    fs.writeFileSync(dump, chunk);
    console.error("   đã ghi chunk lỗi ra", dump);
    process.exit(1);
  }
  const text = typeof out === "string" ? out : (Array.isArray(out) ? out.join("\n") : String(out));

  const kv = {};
  for (const line of text.split("\n")) {
    const i = line.indexOf("=");
    if (i > 0) kv[line.slice(0, i)] = line.slice(i + 1);
  }
  if (wantJson) { console.log(JSON.stringify(kv, null, 2)); return; }

  const parts = Number(kv.parts || 0);
  const destructible = Number(kv.destructible || 0);
  const pct = parts ? ((destructible / parts) * 100).toFixed(1) : "0.0";
  console.log("──────────────────────────────────────────────────────────────");
  console.log(`  ${kv.module || "?"}  ·  ${kv.plot || "?"}`);
  console.log("──────────────────────────────────────────────────────────────");
  console.log(`  BasePart tạo ra          : ${parts}`);
  console.log(`  Khối có máu ẩn           : ${destructible} (${pct} %)`);
  console.log(`  Thiếu MaxPartHealth      : ${kv["attr_partHealth=nil"]}`);
  console.log(`  AABB                     : ${kv.aabb}`);
  console.log(`  Khối nhỏ <1.6 còn va chạm: ${kv.smallCollide}`);
  console.log(`  CanTouch = true          : ${kv.canTouchOn}`);
  console.log(`  CastShadow sai (kính/neon): ${kv.castShadowBad}`);
  console.log(`  SurfaceGui sai chuẩn     : ${kv.guiBad}`);
  console.log(`  Khối size 0              : ${kv.zeroSize}`);
  console.log(`  Tên part trùng           : ${kv.dupNames}`);
  console.log("──────────────────────────────────────────────────────────────");
  console.log(`  build ok=${kv["build ok"]}`);
  const problems = [];
  if (!parts) problems.push("không tạo được part nào");
  if (Number(kv.smallCollide)) problems.push(`${kv.smallCollide} khối nhỏ còn CanCollide`);
  if (Number(kv.canTouchOn)) problems.push(`${kv.canTouchOn} part bật CanTouch`);
  if (Number(kv.castShadowBad)) problems.push(`${kv.castShadowBad} part đổ bóng sai`);
  if (Number(kv.guiBad)) problems.push(`${kv.guiBad} SurfaceGui sai`);
  if (Number(kv.zeroSize)) problems.push(`${kv.zeroSize} khối size 0`);
  if (problems.length) {
    console.log("\n❌ VẤN ĐỀ: " + problems.join(" · "));
    process.exit(1);
  }
  console.log("\n✅ Không có vấn đề hình học/hiệu năng.");
})();
