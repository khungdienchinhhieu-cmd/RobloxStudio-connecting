--!strict
--[[
	Carryables.luau  (Sync v25 — CƠ CHẾ TAY / KHIÊNG VÁC)
	================================================================================
	Người chơi có thể **nhặt đồ bằng tay** rồi tha đi khắp thành phố:
	  • Lốp xe ở Los Santos Customs
	  • Gạch vụn ngay cạnh công trường / chân tường
	  • Thùng hàng ở 24/7 Supermarket
	  • Cọc giao thông ở chỗ LSPD dựng rào
	Nhặt bằng ProximityPrompt (E), mang theo bằng mối hàn vào nhân vật,
	**G để thả**, **chuột trái / F để ném** — ném trúng tường thì trừ PartHealth
	(cơ chế phá huỷ sẵn có), trúng NPC / người chơi thì trừ máu.

	File này chỉ chứa DỮ LIỆU (kích thước, màu, sát thương...). Logic nằm ở
	`src/server/CarryManager.luau` (vật lý + hàn) và `src/client/CarryClient.luau`
	(HUD + tư thế hai tay).
]]

local Carryables = {}

export type Kind = {
	id: string,
	display: string,
	icon: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?,
	mass: number,
	damage: number,
	throwSpeed: number,
	-- góc xoay cố định khi cầm (độ) — lốp xe nằm nghiêng cho tự nhiên
	carryTilt: Vector3?,
}

-- ══════════════════════════════════════════════════════════════════════════════
-- ĐỒ CÓ THỂ NHẶT
-- ══════════════════════════════════════════════════════════════════════════════

Carryables.KINDS = {
	tire = {
		id = "tire",
		display = "Lốp xe",
		icon = "🛞",
		size = Vector3.new(1.0, 2.8, 2.8),
		color = Color3.fromRGB(28, 29, 33),
		material = Enum.Material.Rubber,
		shape = Enum.PartType.Cylinder,
		mass = 1.6,
		damage = 22,
		throwSpeed = 52,
		carryTilt = Vector3.new(0, 0, 90),
	},
	brick = {
		id = "brick",
		display = "Viên gạch",
		icon = "🧱",
		size = Vector3.new(1.7, 0.72, 0.78),
		color = Color3.fromRGB(166, 78, 58),
		material = Enum.Material.Sandstone,
		mass = 0.45,
		damage = 36,
		throwSpeed = 78,
	},
	crate = {
		id = "crate",
		display = "Thùng hàng",
		icon = "📦",
		size = Vector3.new(2.6, 2.4, 2.6),
		color = Color3.fromRGB(146, 104, 62),
		material = Enum.Material.WoodPlanks,
		mass = 1.2,
		damage = 14,
		throwSpeed = 46,
	},
	cone = {
		id = "cone",
		display = "Cọc giao thông",
		icon = "🚧",
		size = Vector3.new(1.5, 2.3, 1.5),
		color = Color3.fromRGB(240, 118, 34),
		material = Enum.Material.Plastic,
		mass = 0.28,
		damage = 9,
		throwSpeed = 70,
	},
	bottle = {
		id = "bottle",
		display = "Chai thuỷ tinh",
		icon = "🍾",
		size = Vector3.new(0.62, 1.5, 0.62),
		color = Color3.fromRGB(96, 148, 92),
		material = Enum.Material.Glass,
		mass = 0.2,
		damage = 26,
		throwSpeed = 86,
	},
} :: { [string]: Kind }

-- ══════════════════════════════════════════════════════════════════════════════
-- KỆ HÀNG Ở TỪNG CỬA HÀNG
-- ------------------------------------------------------------------------------
-- `anchor` = id của quầy trong BuildingServices; đồ được xếp thành vòng quanh quầy
-- để chắc chắn nằm ngoài khối nhà (quầy luôn đặt ở mép ô đất).
-- ══════════════════════════════════════════════════════════════════════════════

export type Rack = {
	anchor: string,
	kind: string,
	count: number,
	spread: number,
	note: string,
}

Carryables.RACKS = {
	{ anchor = "C1_REPAIR", kind = "tire", count = 6, spread = 7, note = "Kệ lốp dự phòng ở Los Santos Customs" },
	{ anchor = "C1_REPAIR", kind = "brick", count = 6, spread = 9, note = "Gạch vụn cạnh xưởng sửa xe" },
	{ anchor = "C3W_SNACK", kind = "crate", count = 4, spread = 6, note = "Thùng hàng trước 24/7 Supermarket" },
	{ anchor = "C3W_SNACK", kind = "bottle", count = 5, spread = 5, note = "Chai bia vứt trước cửa hàng" },
	{ anchor = "C3E_BAIL", kind = "cone", count = 6, spread = 8, note = "Cọc giao thông LSPD dựng rào" },
	{ anchor = "D2_DEPOSIT", kind = "brick", count = 5, spread = 8, note = "Vật liệu sửa chữa trước Maze Bank" },
	{ anchor = "C2_TESTDRIVE", kind = "cone", count = 4, spread = 7, note = "Cọc chia làn ở bãi xe Legion Square" },
} :: { Rack }

function Carryables.get(id: string): Kind?
	return Carryables.KINDS[id]
end

return Carryables
