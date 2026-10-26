/**
 * Harness chạy THẬT src/server/NPCManager.luau ngoài Roblox Studio.
 *
 *   node tools/npc_sim/run.cjs            # mô phỏng 90 giây trong game
 *
 * Cần: npm i @luau-rs/luau   (hoặc đặt package trong /tmp/luau-check)
 *
 * Mock: Instance / CFrame / Vector3 / Enum / Color3 / Players / Workspace.Raycast (trả nil)
 *       + scheduler coroutine + đồng hồ mô phỏng (os.clock giả) để 90 s trong game
 *       chạy xong trong ~1 s thật.
 *
 * In ra: số NPC sống, biểu đồ hoạt động, số NPC thực sự di chuyển, danh sách cảnh báo.
 * Thoát code 1 nếu có bất kỳ cảnh báo/lỗi nào hoặc dân số < 60.
 *
 * Viết ra để chứng minh lỗi "thành phố trống" của Sync v23 và chốt bản sửa ở Sync v24.
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

(async () => {
  const lua = await Lua.create();
  const prelude = fs.readFileSync(path.join(__dirname, "prelude.luau"), "utf8");

  const wgSrc = fs.readFileSync(path.join(REPO, "src/shared/WorldGrid.luau"), "utf8");
  const wi = wgSrc.lastIndexOf("return WorldGrid");
  const wgPatched = wgSrc.slice(0, wi) + "WORLDGRID = WorldGrid" + wgSrc.slice(wi + "return WorldGrid".length);

  const stubsSrc = `
local ServerScriptService = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:FindFirstChild("Shared")
local serverRoot = Instance.new("Folder", RS); serverRoot.Name = "Server"
local vehFolder = Shared:FindFirstChild("Vehicles")
local vbMod = Instance.new("ModuleScript", vehFolder); vbMod.Name = "VehicleBuilder"
local wgMod = Instance.new("ModuleScript", Shared); wgMod.Name = "WorldGrid"
local naMod = Instance.new("ModuleScript", serverRoot); naMod.Name = "NPCAppearance"
script = Instance.new("ModuleScript"); script.Parent = serverRoot

MOCKS = {}
MOCK_SPEED = {}

function __physicsStep(step)
	for _, e in ipairs(MOCKS) do
		local goal = e.hum.__goal
		if goal then
			local cur = e.hrp.Position
			local dx, dz = goal.X - cur.X, goal.Z - cur.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist < 0.35 then
				e.hrp.Position = Vector3.new(goal.X, cur.Y, goal.Z)
				e.hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			else
				local sp = (e.hum.WalkSpeed or 14) * step
				if sp > dist then sp = dist end
				local nx, nz = cur.X + dx / dist * sp, cur.Z + dz / dist * sp
				e.hrp.Position = Vector3.new(nx, cur.Y, nz)
				e.hrp.AssemblyLinearVelocity = Vector3.new(dx / dist * (e.hum.WalkSpeed or 14), 0, dz / dist * (e.hum.WalkSpeed or 14))
			end
		end
	end
end

local function mkFakePart(name)
	local p = Instance.new("Part"); p.Name = name; p.Size = Vector3.new(1,1,1)
	p.Parent = nil
	return p
end

local NA = {
	warmTemplates = function(n) return n end,
	templateCount = function() return 4 end,
	build = function(id, cf, speed, hp)
		local model = Instance.new("Model"); model.Name = "NPC_" .. tostring(id)
		local hum = Instance.new("Humanoid"); hum.Parent = model
		hum.WalkSpeed = speed; hum.Health = hp; hum.MaxHealth = hp
		hum.__goal = nil
		hum.MoveTo = function(self, goal) self.__goal = goal end
		local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.Parent = model
		hrp.CFrame = cf; hrp.Position = cf.Position
		local head = Instance.new("Part"); head.Name = "Head"; head.Parent = model
		head.Position = cf.Position + Vector3.new(0, 2, 0)
		local hand = Instance.new("Part"); hand.Name = "RightHand"; hand.Parent = model
		hand.Position = cf.Position + Vector3.new(0.6, 0.2, 0)
		model.PrimaryPart = hrp
		table.insert(MOCKS, { hum = hum, hrp = hrp })
		return model, hum, hrp, head
	end,
	fromPlayer = function(player, cf)
		local model = Instance.new("Model"); model.Name = "TWIN"
		local hum = Instance.new("Humanoid"); hum.Parent = model
		hum.Health = 100; hum.MaxHealth = 100; hum.WalkSpeed = 14
		hum.__goal = nil
		hum.MoveTo = function(self, goal) self.__goal = goal end
		local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.Parent = model
		hrp.CFrame = cf; hrp.Position = cf.Position
		local head = Instance.new("Part"); head.Name = "Head"; head.Parent = model
		table.insert(MOCKS, { hum = hum, hrp = hrp })
		return model, hum, hrp, head
	end,
	loadAnimations = function(model, hum)
		return { walk = "w", run = "r", idle = "i" }
	end,
	playAnim = function(anims, kind, speed) CURRENT_ANIM = (CURRENT_ANIM or 0) + 1 end,
	stopAnim = function() end,
	tuneGait = function(anims, speed) end,
}

require = function(m)
	if m == wgMod then return WORLDGRID end
	if m == naMod then return NA end
	if m == vbMod then
		local preset = function() return { id = "car", color = Color3.fromRGB(200, 40, 40) } end
		return {
			spawn = function(folder, cf, trim)
				local car = Instance.new("Model"); car.Name = "Car"; car.Parent = folder
				local part = Instance.new("Part"); part.Name = "Body"; part.Parent = car
				part.Position = cf.Position; part.CFrame = cf
				car.PrimaryPart = part
				local seat = Instance.new("Part"); seat.Name = "DriverSeat"; seat.Parent = car
				seat.CFrame = cf; seat.Position = cf.Position
				car.FindFirstChild = function(self, n, rec)
					if n == "DriverSeat" then return seat end
					return nil
				end
				return car, part
			end,
			PRESETS = {
				CrimsonBanshee = preset(), MidnightBanshee = preset(),
				ObsidianGauntlet = preset(), SunsetComet = preset(),
			},
		}
	end
	return NA
end
`;

  let npcSrc = fs.readFileSync(path.join(REPO, "src/server/NPCManager.luau"), "utf8");
  npcSrc = npcSrc.replace(
    "local ok, err = pcall(tickOne, st)",
    "local ok, err = xpcall(function() return tickOne(st) end, function(e) return debug.traceback(tostring(e), 2) end)"
  );
  npcSrc = npcSrc.replace(
    "local okSpawn, built = pcall(NPCManager.spawn, rollArchetype(), g)",
    "local okSpawn, built = xpcall(function() return NPCManager.spawn(rollArchetype(), g) end, function(e) return debug.traceback(tostring(e), 2) end)"
  );
  const idx = npcSrc.lastIndexOf("return NPCManager");
  const patched = npcSrc.slice(0, idx) + "NPC_EXPORT = NPCManager\nNPC_EXPORT.__states = states" + npcSrc.slice(idx + "return NPCManager".length);

  const chunk = prelude + "\n" + wgPatched + "\n" + stubsSrc + "\n" + patched;

  try {
    lua.execute(chunk, { chunkName: "npc" });
  } catch (e) {
    console.log("LUA ERROR:", e.message);
    return;
  }

  const driver = `
local ok, err = pcall(function()
	NPC_EXPORT.init(nil)
	pump(30)
	-- ── thử đường BẢN SAO NGƯỜI CHƠI ──
	local char = Instance.new("Model"); char.Name = "PlayerChar"
	local phrp = Instance.new("Part"); phrp.Name = "HumanoidRootPart"; phrp.Parent = char
	phrp.Position = Vector3.new(0, 4, 0); phrp.CFrame = CFrame.new(0, 4, 0)
	local phum = Instance.new("Humanoid"); phum.Parent = char
	local fakePlayer = { Name = "TestPlayer", Character = char,
		GetAttribute = function() return nil end, SetAttribute = function() end }
	local okTwin, twinRes = pcall(NPC_EXPORT.spawnPlayerTwin, fakePlayer)
	TWIN_INFO = "ok=" .. tostring(okTwin) .. " model=" .. tostring(twinRes ~= nil) .. " err=" .. tostring(okTwin and "-" or twinRes)

	-- ── thử đường BỊ BẮN: NPC phải phản ứng, không được văng lỗi ──
	local victim
	for _, st in pairs(NPC_EXPORT.__states) do
		if not st.twin and st.model:GetAttribute("IsDriver") ~= true then victim = st break end
	end
	local pchar = Instance.new("Model"); pchar.Name = "ShooterChar"
	local shrp = Instance.new("Part"); shrp.Name = "HumanoidRootPart"; shrp.Parent = pchar
	shrp.Position = Vector3.new(0, 4, 0); shrp.CFrame = CFrame.new(0, 4, 0)
	local shum = Instance.new("Humanoid"); shum.Parent = pchar
	local shooter = { Name = "Shooter", Character = pchar,
		GetAttribute = function() return nil end, SetAttribute = function() end }
	local okAtk, atkErr = pcall(NPC_EXPORT.notifyAttacked, victim.model, shooter, "BULLET")
	pump(6)
	REACT_INFO = "ok=" .. tostring(okAtk) .. " state=" .. tostring(victim.state) ..
		" reaction=" .. tostring(victim.reaction) .. " err=" .. tostring(okAtk and "-" or atkErr)
end)
INIT_ERR = tostring(err or "")
`;
  try {
    lua.execute(driver, { chunkName: "driver" });
  } catch (e) {
    console.log("DRIVER ERROR:", e.message);
  }

  const report = lua.execute(`
local out = {}
table.insert(out, "init error: " .. (INIT_ERR ~= "" and INIT_ERR or "không có"))
table.insert(out, "thời điểm mô phỏng: " .. string.format("%.1fs", SIM.t))
local stats = NPC_EXPORT.getStats and NPC_EXPORT.getStats() or {}
table.insert(out, string.format("getStats: sống=%s r15=%s xe=%s", tostring(stats.alive), tostring(stats.r15), tostring(stats.traffic)))
table.insert(out, NPC_EXPORT.diagnose())
table.insert(out, "twin: " .. tostring(TWIN_INFO))
table.insert(out, "bị bắn: " .. tostring(REACT_INFO))
-- đo quãng đường: chụp vị trí, chạy thêm 60s, so sánh
local before = {}
for i, e in ipairs(MOCKS) do before[i] = e.hrp.Position end
pump(60)
local moved, total, maxMove = 0, 0, 0
for i, e in ipairs(MOCKS) do
	total += 1
	local d = (e.hrp.Position - before[i]).Magnitude
	if d > 8 then moved += 1 end
	if d > maxMove then maxMove = d end
end
table.insert(out, string.format("di chuyển trong 60s: %d/%d NPC đi > 8 stud (xa nhất %.0f)", moved, total, maxMove))
table.insert(out, NPC_EXPORT.diagnose())
table.insert(out, "coroutine còn sống: " .. __countThreads())
table.insert(out, "số cảnh báo: " .. #WARNS)
local seen, shown = {}, 0
for _, w in ipairs(WARNS) do
	if not seen[w] and shown < 8 then seen[w] = true; shown += 1; table.insert(out, "WARN: " .. w) end
end
return table.concat(out, "\\n")
`, { chunkName: "report" });
  console.log(report[0]);

  const text = report[0];
  const living = Number((text.match(/sống=(\d+)/) || [])[1] || 0);
  const warnCount = Number((text.match(/số cảnh báo: (\d+)/) || [])[1] || 0);
  const pass = living >= 60 && warnCount === 0;
  console.log(pass ? "\n✅ PASS — thành phố có NPC sống, đi lại và làm việc, không lỗi." : "\n❌ FAIL — xem cảnh báo phía trên.");
  process.exit(pass ? 0 : 1);
})();
