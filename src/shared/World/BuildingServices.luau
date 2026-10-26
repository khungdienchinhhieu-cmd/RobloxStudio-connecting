--!strict
--[[
	BuildingServices.luau  (Sync v25 — "MỖI NHÀ PHẢI CÓ CHỨC NĂNG")
	================================================================================
	Trước đây các công trình chỉ để NGẮM: LS Customs có UI độ xe, còn LSPD / Maze Bank /
	Supermarket bấm vào không có gì xảy ra. Module này khai báo **mỗi ô đất có ít nhất
	một dịch vụ dùng được**, kèm giá tiền và vị trí đặt quầy (quầy = ProximityPrompt +
	biển hiệu neon + cột sáng chỉ đường).

	ServiceManager (server) sẽ đọc bảng này rồi dựng quầy thật trong thành phố.
	Nếu ô đất chưa có công trình (agent chưa dựng xong) thì quầy **tự động bật lên**
	ngay khi module của ô đó được nạp — không phải sửa file này.

	QUY ƯỚC TOẠ ĐỘ (v25.2 — số đo THẬT, có công cụ kiểm chứng):
	  • `offset` tính từ TÂM ô đất (X ngang, Z sâu), đơn vị stud, bám lưới 0,5 stud.
	  • Mỗi offset được GIẢI BẰNG MÁY, không đoán: `tools/building_sim/counter_check.cjs --solve`
	    dựng lại công trình thật trong Luau VM, đo AABB có xoay, rồi tìm điểm gần cửa nhất mà
	    - nằm trong ô đất (cách biên ≥ 4 stud),
	    - không khối nào (tường/kính/cửa cuốn/cọc chắn/bậc) nằm trong bán kính 4 stud
	      (bán kính đế quầy 3,95 stud) ở độ cao 1,15…4,15,
	    - có mặt đỡ thật dưới chân.
	    Chạy lại lúc nào cũng ra đúng các số dưới đây → không ai sửa tay làm lệch được.
	  • Toạ độ thật (tâm ô + offset) và mặt đỡ đo được:
	      C1_REPAIR    (−204,0 · 62,5)  nền 1,28   sân trước LS Customs
	      C3W_SNACK    (171,5 · 101,0)  nền 1,30   trước cửa kính 24/7
	      C3W_ARMOR    (176,5 · 101,0)  nền 1,30
	      C3W_AMMO     (182,0 · 101,0)  nền 1,30
	      C3E_BAIL     (252,0 ·  83,5)  nền 1,34   sân LSPD, dưới cổng chính
	      C3E_ARSENAL  (260,0 ·  83,5)  nền 1,34
	      D2_DEPOSIT   ( −3,5 · −64,5)  nền 1,27   quảng trường Maze Bank
	      D2_WITHDRAW  (  3,0 · −64,5)  nền 1,27
	      D1_SHOWROOM  (−226,0 · −76,0) nền 1,37   sân đỗ Luxury Autos
	      D3_CINEMA    ( 226,0 · −76,0) nền 1,29   sân sao dưới marquee rạp phim
	      E1_SPA       (−447,0 · −76,0) nền 1,31   sàn đá cạnh hồ bơi biệt thự
	      E2_GARAGE    ( 447,0 · −76,0) nền 1,29   sân rào lưới trước 3 cửa cuốn
	      E3_FOOD      (−445,5 · 119,0) nền 1,41   sân trước quán ăn Seoul
	      E4_MALL      ( 449,0 · 123,0) nền 1,29   quảng trường trước Galleria
	  • Y KHÔNG hard-code: `ServiceManager.groundYAt()` raycast xuống lấy mặt sàn thật
	    (1,27–1,37 tuỳ ô), chênh lệch với vỉa hè (1,15) tới 0,22 stud nên nếu để 1,15
	    thì đế quầy bị chôn, còn 1,40 thì lơ lửng.
	  • Ô chưa dựng dùng (0, 0, 56) — hướng ra đại lộ; khi agent nạp module thì chạy
	    `counter_check --solve` để chốt lại theo cửa thật.
]]

local WorldGrid = require(script.Parent.Parent:WaitForChild("WorldGrid"))

local BuildingServices = {}

export type ServiceKind =
	"REPAIR_CAR"
	| "SPAWN_CAR"
	| "HEAL"
	| "HEAL_FULL"
	| "ARMOR"
	| "AMMO"
	| "CLEAR_WANTED"
	| "UNLOCK_WEAPON"
	| "BANK_DEPOSIT"
	| "BANK_WITHDRAW"
	| "CINEMA"
	| "CAR_WASH"

export type Service = {
	id: string,
	plotId: string,
	title: string,
	subtitle: string,
	icon: string,
	kind: ServiceKind,
	price: number,
	prompt: string,
	offset: Vector3,
	detail: string?,
}

-- ══════════════════════════════════════════════════════════════════════════════
-- BẢNG DỊCH VỤ — mỗi ô đất một chức năng (ô đôi C3 tách West/East)
-- ══════════════════════════════════════════════════════════════════════════════

local LIST: { Service } = {
	-- ── ĐÃ DỰNG ────────────────────────────────────────────────────────────────
	{
		id = "C1_REPAIR",
		plotId = "Plot_C1",
		title = "LOS SANTOS CUSTOMS",
		subtitle = "Sửa chữa · sơn · độ xe",
		icon = "🔧",
		kind = "REPAIR_CAR",
		price = 250,
		prompt = "Sửa xe  [$250]",
		offset = Vector3.new(22.0, 0, 4.5),
		detail = "Sửa toàn bộ hư hỏng cho chiếc xe bạn đang ngồi / đứng cạnh.",
	},
	{
		id = "C3W_SNACK",
		plotId = "Plot_C3_West",
		title = "24/7 SUPERMARKET",
		subtitle = "Snack & nước uống",
		icon = "🍫",
		kind = "HEAL",
		price = 25,
		prompt = "Mua snack  [$25]",
		offset = Vector3.new(-54.5, 0, 43.0),
		detail = "Hồi 35 máu ngay lập tức.",
	},
	{
		id = "C3W_ARMOR",
		plotId = "Plot_C3_West",
		title = "24/7 SUPERMARKET",
		subtitle = "Áo giáp chống đạn",
		icon = "🛡️",
		kind = "ARMOR",
		price = 250,
		prompt = "Mua giáp  [$250]",
		offset = Vector3.new(-49.5, 0, 43.0),
		detail = "Nạp đầy 100% giáp.",
	},
	{
		id = "C3W_AMMO",
		plotId = "Plot_C3_West",
		title = "24/7 SUPERMARKET",
		subtitle = "Hộp đạn dự phòng",
		icon = "📦",
		kind = "AMMO",
		price = 150,
		prompt = "Mua đạn  [$150]",
		offset = Vector3.new(-44.0, 0, 43.0),
		detail = "Nạp đầy băng đạn dự phòng cho mọi súng đang có.",
	},
	{
		id = "C3E_BAIL",
		plotId = "Plot_C3_East",
		title = "MISSION ROW LSPD",
		subtitle = "Nộp phạt · xoá truy nã",
		icon = "🚔",
		kind = "CLEAR_WANTED",
		price = 500,
		prompt = "Nộp phạt  [$500 / sao]",
		offset = Vector3.new(26.0, 0, 25.5),
		detail = "Xoá toàn bộ số sao truy nã. Giá = 500 × số sao.",
	},
	{
		id = "C3E_ARSENAL",
		plotId = "Plot_C3_East",
		title = "MISSION ROW LSPD",
		subtitle = "Kho vũ khí (chỉ khi sạch án)",
		icon = "🎖️",
		kind = "UNLOCK_WEAPON",
		price = 0,
		prompt = "Nhận Carbine Rifle",
		offset = Vector3.new(34.0, 0, 25.5),
		detail = "Cấp Carbine Rifle + đầy đạn. Yêu cầu 0 sao truy nã.",
	},
	{
		id = "D2_DEPOSIT",
		plotId = "Plot_D2",
		title = "MAZE BANK",
		subtitle = "Gửi tiền vào tài khoản",
		icon = "🏦",
		kind = "BANK_DEPOSIT",
		price = 500,
		prompt = "Gửi $500",
		offset = Vector3.new(-3.5, 0, 67.5),
		detail = "Chuyển $500 tiền mặt vào tài khoản ngân hàng (an toàn khi bị bắt).",
	},
	{
		id = "D2_WITHDRAW",
		plotId = "Plot_D2",
		title = "MAZE BANK",
		subtitle = "Rút tiền mặt",
		icon = "🏧",
		kind = "BANK_WITHDRAW",
		price = 500,
		prompt = "Rút $500",
		offset = Vector3.new(3.0, 0, 67.5),
		detail = "Rút $500 từ tài khoản ra tiền mặt.",
	},
	{
		id = "C2_TESTDRIVE",
		plotId = "Plot_C2",
		title = "LEGION SQUARE",
		subtitle = "Bãi xe thử miễn phí",
		icon = "🚙",
		kind = "SPAWN_CAR",
		price = 0,
		prompt = "Lấy xe thử",
		offset = Vector3.new(0, 0, -6),
		detail = "Giao một chiếc xe ngay trước mặt — miễn phí.",
	},

	-- ── CHỜ AGENT DỰNG (quầy tự bật khi công trình xuất hiện) ──────────────────
	{
		id = "D1_SHOWROOM",
		plotId = "Plot_D1",
		title = "ROCKFORD LUXURY AUTOS",
		subtitle = "Showroom siêu xe",
		icon = "🏎️",
		kind = "SPAWN_CAR",
		price = 2000,
		prompt = "Mua siêu xe  [$2000]",
		offset = Vector3.new(0.0, 0, 56.0),
		detail = "Giao siêu xe ngay trước showroom.",
	},
	{
		id = "D3_CINEMA",
		plotId = "Plot_D3",
		title = "VINEWOOD CINEMA",
		subtitle = "Vé xem phim",
		icon = "🎬",
		kind = "CINEMA",
		price = 50,
		prompt = "Mua vé  [$50]",
		offset = Vector3.new(0, 0, 56),
		detail = "Xem phim 3 giây: hồi đầy máu + thưởng $150 tiền cát-xê.",
	},
	{
		id = "E1_SPA",
		plotId = "Plot_E1",
		title = "PACIFIC BLUFFS VILLA",
		subtitle = "Spa hồi phục",
		icon = "🧖",
		kind = "HEAL_FULL",
		price = 400,
		prompt = "Vào spa  [$400]",
		offset = Vector3.new(0, 0, 56),
		detail = "Hồi đầy máu + đầy giáp.",
	},
	{
		id = "E2_GARAGE",
		plotId = "Plot_E2",
		title = "LA MESA GARAGE",
		subtitle = "Garage độ xe công nghiệp",
		icon = "🛠️",
		kind = "REPAIR_CAR",
		price = 150,
		prompt = "Sửa xe  [$150]",
		offset = Vector3.new(0, 0, 56),
		detail = "Sửa xe giá rẻ hơn LS Customs.",
	},
	{
		id = "E3_FOOD",
		plotId = "Plot_E3",
		title = "SEOUL NIGHT MARKET",
		subtitle = "Quán ăn đêm",
		icon = "🍜",
		kind = "HEAL",
		price = 20,
		prompt = "Ăn một tô  [$20]",
		offset = Vector3.new(1.5, 0, 61),
		detail = "Hồi 50 máu.",
	},
	{
		id = "E4_MALL",
		plotId = "Plot_E4",
		title = "RICHMAN GALLERIA",
		subtitle = "Combo giáp + đạn",
		icon = "🛍️",
		kind = "ARMOR",
		price = 350,
		prompt = "Mua combo  [$350]",
		offset = Vector3.new(2.0, 0, 65),
		detail = "Đầy giáp + đầy đạn dự phòng.",
	},
}

BuildingServices.LIST = LIST

-- ══════════════════════════════════════════════════════════════════════════════
-- TÍNH TOẠ ĐỘ THẾ GIỚI CỦA QUẦY
-- ══════════════════════════════════════════════════════════════════════════════

function BuildingServices.plotById(plotId: string)
	for _, plot in ipairs(WorldGrid.PLOTS) do
		if plot.id == plotId then
			return plot
		end
	end
	return nil
end

--[[
	Vị trí quầy trong thế giới.
	`offset` khai báo ở trên là toạ độ tương đối so với tâm ô đất; hàm này cộng thêm
	tâm ô đất + cao độ vỉa hè để có Vector3 tuyệt đối.
]]
--[[
	Vị trí quầy trong thế giới = TÂM Ô ĐẤT + `offset`.
	Các offset dưới đây KHÔNG phải số tuỳ tiện: chúng đặt quầy ngay TRƯỚC CỬA của
	công trình đã dựng (lấy từ toạ độ cửa thật trong từng module):
	  • LS Customs   — cửa đi bộ tại X = −206,5 · mặt tiền Z = 51
	  • 24/7         — cửa chính tại X = 175 · Z = 92 (mặt Nam ra Vespucci Blvd)
	  • LSPD         — sảnh chính tại X ≈ 255 · Z = 70 (mặt Nam)
	  • Maze Bank    — cổng chính tại X = 0 · Z = −65 (trên Olympic Fwy)
	Ô đất chưa dựng thì quầy nằm ở mép Nam của ô (Z = tâm + 56) — khi agent dựng
	xong, chỉ cần chỉnh lại offset này là quầy đứng đúng cửa.
]]
function BuildingServices.worldPosition(service: Service): Vector3?
	local plot = BuildingServices.plotById(service.plotId)
	if not plot then
		return nil
	end
	return Vector3.new(
		plot.center.X + service.offset.X,
		(WorldGrid :: any).SIDEWALK_TOP_Y or 1.15,
		plot.center.Z + service.offset.Z
	)
end

--[[ Danh sách dịch vụ của một ô đất ]]
function BuildingServices.forPlot(plotId: string): { Service }
	local out = {}
	for _, s in ipairs(LIST) do
		if s.plotId == plotId then
			table.insert(out, s)
		end
	end
	return out
end

--[[ Toàn bộ plotId có khai báo dịch vụ ]]
function BuildingServices.plotsWithServices(): { string }
	local seen: { [string]: boolean } = {}
	local out = {}
	for _, s in ipairs(LIST) do
		if not seen[s.plotId] then
			seen[s.plotId] = true
			table.insert(out, s.plotId)
		end
	end
	return out
end

return BuildingServices
