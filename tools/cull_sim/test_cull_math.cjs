/**
 * Kiểm thử CullMath.luau (logic CityCuller) bằng Luau VM thật.
 *   node tools/cull_sim/test_cull_math.cjs
 * Thoát 0 nếu mọi ca đều đúng, 1 nếu có ca sai.
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
const src = fs.readFileSync(path.join(REPO, "src/client/CullMath.luau"), "utf8")
  .replace(/^--!strict\s*$/m, "")
  .replace(/^return CullMath\s*$/m, "");

const cases = `

local NEAR, FAR, BEHIND, HYST = 380, 900, 460, 40
local fails = {}
local function check(name, got, want)
  if got ~= want then table.insert(fails, name .. " got=" .. tostring(got) .. " want=" .. tostring(want)) end
end

-- distToBoxXZ
check("trong hộp = 0", C.distToBoxXZ(0, 0, -92, -72, 92, 72), 0)
check("cạnh Đông 100 stud", C.distToBoxXZ(192, 0, -92, -72, 92, 72), 100)
check("góc 3-4-5", C.distToBoxXZ(95, 76, -92, -72, 92, 72), 5)

-- BUG GỐC: tâm ô nằm xa nhưng CẠNH ô ở gần thì phải GIỮ
-- ô [-92..92], người đứng x=200: tâm cách 200, cạnh cách 108 → phải giữ (<=460 và cạnh 108 < 380)
check("cạnh gần → giữ", C.decide(C.distToBoxXZ(200, 0, -92, -72, 92, 72), false, true, NEAR, FAR, BEHIND, HYST), true)

-- gần hẳn → luôn giữ, dù không thấy
check("gần, khuất → giữ", C.decide(100, false, false, NEAR, FAR, BEHIND, HYST), true)
-- xa hẳn → luôn cất, dù thấy
check("xa, thấy → cất", C.decide(1000, true, true, NEAR, FAR, BEHIND, HYST), false)
-- dải trễ gần (dist 350 ≤ 380-40 = 340? không) → dải giữa
check("dải giữa 400, đang hiện → giữ (trễ)", C.decide(400, true, true, NEAR, FAR, BEHIND, HYST), true)
check("dải giữa 400, đang ẩn, thấy → vẫn ẩn (không chớp)", C.decide(400, true, false, NEAR, FAR, BEHIND, HYST), false)
check("dải giữa 600, khuất → cất", C.decide(600, false, true, NEAR, FAR, BEHIND, HYST), false)
check("dải giữa 600, thấy → giữ", C.decide(600, true, false, NEAR, FAR, BEHIND, HYST), true)
check("dải trễ 400, đang ẩn → vẫn ẩn", C.decide(400, false, false, NEAR, FAR, BEHIND, HYST), false)
check("dải trễ 455 (≤460) giữ nguyên hiện", C.decide(455, false, true, NEAR, FAR, BEHIND, HYST), true)

-- debounce: cất cần 2 nhịp liên tiếp
local hide, n = C.hideDebounce(false, 0, 2)
check("nhịp 1 chưa cất", hide, false)
check("nhịp 1 đếm=1", n, 1)
hide, n = C.hideDebounce(false, n, 2)
check("nhịp 2 cất", hide, true)
hide, n = C.hideDebounce(true, n, 2)
check("giữ reset đếm", n, 0)
check("giữ không cất", hide, false)
hide, n = C.hideDebounce(false, 0, 2)
check("sau reset, nhịp 1 vẫn chưa cất", hide, false)

-- corners: 8 góc
check("8 góc", #C.corners(-1, 0, -1, 1, 2, 1), 8)

return table.concat(fails, "\\n")
`;

const body = cases.replace("local C = CullMath", "local C = CullMath");
const code = src + "\n" + "local C = CullMath\n" + body.split("\n").slice(1).join("\n");

(async () => {
  const lua = await Lua.create();
  let res;
  try {
    res = await lua.execute(code);
  } catch (e) {
    console.error("LỖI LUAU:", String(e.message || e).slice(0, 500));
    process.exit(1);
  }
  const fails = String(res ?? "").trim();
  const count = (code.match(/^check\(/gm) || []).length;
  if (fails) {
    console.log("❌ CullMath sai:\n" + fails);
    process.exit(1);
  }
  console.log(`✅ CullMath: ${count} ca kiểm thử đều đúng`);
  process.exit(0);
})();
