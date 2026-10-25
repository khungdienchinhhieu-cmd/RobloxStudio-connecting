# 🤖 HỆ THỐNG ĐIỀU PHỐI ĐA-AGENT SONG SONG (MULTI-AGENT PARALLEL PROTOCOL)
> **Kho lưu trữ:** `khungdienchinhhieu-cmd/RobloxStudio-connecting`  
> **Mục tiêu:** Cho phép mở **nhiều phiên Arena.ai chạy nhiều Agent độc lập cùng lúc** để xây dựng các công trình & hạ tầng thành phố **GTA V (Los Santos)** nhanh gấp 5–6 lần mà **KHÔNG BAO GIỜ XUNG ĐỘT CODE (0% Git Merge Conflict)** và **ghép khít tọa độ 100%**.

---

## 1. CÁCH VẬN HÀNH NHIỀU PHIÊN ARENA.AI CÙNG LÚC (CHO NGƯỜI DÙNG)

1. **Bước Khởi Tạo Duy Nhất (1 lần trước khi mở các tab mới):**
   - Mỗi phiên Arena.ai mới đều tự động phân nhánh (branch) từ nhánh **`main`** trên GitHub.
   - Do đó, hãy **Merge nhánh nền hiện tại (`arena/b37b6115-robloxstudio-connecting`) vào `main`** trước tiên để `main` có sẵn toàn bộ: Nền Thành Phố v2 (`2,803` parts), Đội Xe GTA V v3, Súng, Cơ chế Máu Ẩn (`DestructionManager`), và Bộ Tự Động Ghép Module (`DistrictRegistry.luau`).
2. **Mở Song Song 3–6 Tab Arena.ai Khác Nhau:**
   - Ở mỗi tab Arena.ai, kết nối vào cùng repo `khungdienchinhhieu-cmd/RobloxStudio-connecting` và dán **1 trong các Prompt Phân Công Mẫu ở Mục 6 bên dưới**.
   - Mỗi Agent sẽ chỉ tạo **ĐÚNG 1 FILE RIÊNG BIỆT** nằm trong `src/shared/World/Modules/<TenModule>.luau`.
3. **Xem Trực Tiếp & Gộp Chung Vào Roblox Studio:**
   - Trên bảng **Arena Live Bridge v3.1** trong Roblox Studio đã có **ô nhập Nhánh GitHub + nút `⇄ main`**:
     - Dán tên nhánh `arena/...` của bất kỳ Agent nào vào ô đó để xem riêng công trình của Agent đó ngay lập tức.
     - Khi Agent làm xong & tạo Pull Request (PR), bạn bấm **Merge PR vào `main`** rồi bấm nút **`⇄ main`** trong Studio -> **`DistrictRegistry` sẽ tự động nạp tất cả công trình của mọi Agent ghép chung vào một thành phố duy nhất!**

---

## 📡 1B. KÊNH BỘ ĐÀM TRÒ CHUYỆN GIỮA CÁC AGENT KHÁC PHIÊN (`bridge/agent-radio.mjs`)

> **Tại sao KHÔNG viết chung vào 1 file `CHAT.md` duy nhất?**  
> Nếu 5 Agent ở 5 nhánh khác nhau cùng sửa chung 1 file `CHAT.md`, các nhánh chưa Merge sẽ không đọc được tin nhắn của nhau và lúc gộp PR sẽ **bị lỗi xung đột dòng (Merge Conflict) 100%**.  
> Thay vào đó, công cụ **`bridge/agent-radio.mjs`** sử dụng cơ chế **Bộ Đàm Xuyên Nhánh (`Cross-Branch Git Radio`)**:
> - Mỗi Agent ghi tin nhắn vào **file riêng gắn mã nhánh của mình** (`agents/notes/<MaO>__<idNhanh>.md`) -> **0% xung đột Git khi gộp PR**!
> - Khi một Agent gõ `read`, script tự động chạy `git fetch origin` và **quét trực tiếp toàn bộ các nhánh `origin/arena/*` đang hoạt động trên GitHub** -> đọc thấy tin nhắn của mọi tab Arena.ai khác **ngay tức thì dù chưa nhánh nào Merge vào `main`!**

1. **Đọc tin nhắn của tất cả các Agent ở các tab khác trước khi bắt đầu:**
   ```bash
   node bridge/agent-radio.mjs read
   ```
2. **Phát tin nhắn nhận ô đất hoặc báo toạ độ lối vào cho các Agent khác:**
   ```bash
   node bridge/agent-radio.mjs say Plot_C1 "Đang nhận dựng LS Customs. Cổng xe vào ở Z=123, X từ -228 đến -208 — Agent đèn đường/cây cọ nhớ chừa trống đoạn này!"
   ```

---

## 2. 5 QUY TẮC BẤT BIẾN BẮT BUỘC MỌI AGENT PHẢI TUÂN THỦ

> **ĐỌC KỸ TRƯỚC KHI VIẾT BẤT KỲ DÒNG CODE NÀO:**

1. **MỘT CÔNG TRÌNH / MỘT AGENT — SIÊU CHỈNH CHU (`1 BUILDING PER SESSION`):**
   - Tuyệt đối không xây 5–6 toà nhà sơ sài cùng lúc. Mỗi Agent chỉ đảm nhận **ĐÚNG 1 CÔNG TRÌNH HOẶC 1 HẠNG MỤC HẠ TẦNG**, chăm chút cực kỳ tỉ mỉ cả kiến trúc mặt tiền, mái, biển hiệu lẫn nội thất bên trong.
2. **CẤM SỬA FILE HỆ THỐNG CHUNG (CHỐNG XUNG ĐỘT GIT 100%):**
   - **KHÔNG ĐƯỢC SỬA** các file lõi: `WorldGrid.luau`, `PartBuilder.luau`, `CityFoundation.luau`, `DistrictRegistry.luau`, `VehicleBuilder.luau`, `DestructionManager.luau`, `VehicleManager.luau`, `GtaHud.luau`, `init.server.luau`, `init.client.luau`.
   - Khi mở PR về `main`, **KHÔNG commit đè `studio-sync.json`** nếu nhánh của bạn chỉ là PR gộp công trình (hoặc chỉ dùng `studio-sync.json` để preview trên nhánh `arena/...` riêng rồi checkout lại `origin/main -- studio-sync.json` trước khi merge PR để 0% conflict!).
   - Chỉ tạo file mới tại: **`src/shared/World/Modules/<MaO_TenCongTrinh>.luau`**.
3. **BẮT BUỘC GHÉP KHỐI & GẮN MÁU ẨN (`PartHealth`) ĐỂ PHÁ HUỶ VẬT LÝ:**
   - Không dựng một bức tường dài 80 studs bằng 1 khối `Part` đặc duy nhất!
   - Phải dùng **`PartBuilder.brickWall`**, **`PartBuilder.segmentedRow`**, hoặc **`PartBuilder.box` / `PartBuilder.wedge` có truyền `integrity = <số máu>`** để từng mảng tường gạch, ô kính cửa sổ, cột hiên, bảng hiệu, kệ hàng đều tự động có thuộc tính máu ẩn (`Destructible = true`, `PartHealth`, `MaxPartHealth`, `StructuralRow`).
   - Khi xe tông (`VehicleManager`) hoặc súng bắn (`WeaponManager`) hết máu ẩn, `DestructionManager` sẽ tự động làm vỡ vụn viên gạch/mảnh kính đó và kéo sập các hàng gạch bên trên!
   - **Lưu ý:** Móng sàn nền nhà hoặc khung dầm thép chịu lực chính nếu không muốn sập toàn bộ sàn thì truyền `integrity = nil` (`Destructible = false`).
4. **TUÂN THỦ TUYỆT ĐỐI HỆ TOẠ ĐỘ `WorldGrid.luau` (`Y_NỀN = 1.15`):**
   - Mặt nhựa đường ở `Y = 0.50`. Mặt vỉa hè và mặt sàn bê tông trong lòng các ô đất nằm chuẩn ở cao độ **`Y = 1.15`** (tránh đặt trùng phẳng `Y = 1.15` gây nhấp nháy Z-fighting — sàn lát riêng của công trình nên đặt mặt trên từ `Y = 1.20` trở lên).
   - Công trình phải nằm gọn **100% bên trong ranh giới `Buildable Bounds`** của ô đất được giao (xem Bảng Mục 3), không lấn ra vỉa hè `9.0` studs bao quanh hay lòng đường.
5. **KIỂM THỬ RENDER 3D TRONG SANDBOX/BROWSER TRƯỚC KHI BÁO CÁO:**
   - Sau khi viết module `.luau`, Agent bắt buộc biên dịch kiểm tra cú pháp Luau (`@luau-rs/luau` hoặc trình giả lập 3D Python/Pillow) và mở ảnh PNG kiểm tra bằng mắt (`read_file`) đảm bảo không lơ lửng, không lệch trục `WedgePart`, không xuyên thấu Z-fighting rồi mới commit/push.

---

## 3. BẢNG PHÂN VÙNG TỌA ĐỘ CÁC Ô ĐẤT (`WORLDGRID` MASTER MAP)

Toàn bộ các ô đất đều có vỉa hè rộng `9.0` studs bao quanh. Công trình phải xây bên trong **Vùng Xây Dựng Lõi (`Inner Buildable Pad` ở cao độ nền `Y = 1.15`)**:

| Mã Phân Vùng | Quận (GTA V) | Tâm Ô `(X, Y, Z)` | Giới Hạn Vùng Xây Lõi `(X_min .. X_max)` | Giới Hạn Vùng Xây Lõi `(Z_min .. Z_max)` | Hướng Mặt Tiền Chính Đề Xuất | Trạng Thái / File Module Chuẩn |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **`Plot_C2`** | **LEGION SQUARE** | `(0, 1.15, 57)` | `-83 .. +83` | `-9 .. +123` | 4 mặt | ✅ **ĐÃ XONG** *(Cấm ghi đè)* |
| **`Plot_C1`** | **DEL PERRO** | `(-218, 1.15, 57)` | **`-299 .. -137`** | **`-9 .. +123`** | Nam (`+Z` nhìn ra Vespucci Blvd) hoặc Đông (`+X`) | 🟢 Giao **Agent #1**: `Plot_C1_LSCustoms.luau` |
| **`Plot_C3`** | **MISSION ROW** | `(+218, 1.15, 57)` | **`+137 .. +299`** | **`-9 .. +123`** | Nam (`+Z` ra Vespucci Blvd) hoặc Tây (`-X` ra Alta St) | 🟢 Giao **Agent #2** (Nửa Tây: `137..212`) & **Agent #3** (Nửa Đông: `222..299`) |
| **`Plot_D2`** | **PILLBOX HILL** | `(0, 1.15, -131)` | **`-83 .. +83`** | **`-199 .. -63`** | Nam (`+Z` nhìn thẳng ra Olympic Fwy & Legion Square) | 🟢 Giao **Agent #4**: `Plot_D2_MazeBank.luau` |
| **`Plot_D1`** | **ROCKFORD HILLS** | `(-218, 1.15, -131)` | **`-299 .. -137`** | **`-199 .. -63`** | Nam (`+Z` ra Olympic Fwy) | 🟢 Giao **Agent #5**: `Plot_D1_RockfordShowroom.luau` |
| **`Plot_D3`** | **DOWNTOWN VINEWOOD** | `(+218, 1.15, -131)` | **`+137 .. +299`** | **`-199 .. -63`** | Bắc (`-Z` ra Vinewood Blvd) hoặc Nam (`+Z`) | 🟢 Giao **Agent #6**: `Plot_D3_VinewoodCinema.luau` |
| **`StreetProps`** | **TOÀN ĐÔ THỊ** | Mép vỉa hè các đại lộ | Dọc mép vỉa hè (`±19` / `±17` từ tâm đường) | Không chặn lòng đường & lối vào garage | Dọc đường | 🟢 Giao **Agent #7**: `Infra_StreetLightsAndPalms.luau` |

> **Chuẩn chiều cao nhân vật R15:** Cao nhân vật đứng `~5.4` studs -> Cửa đi bộ tối thiểu cao **`7.5 - 8.5` studs**, trần mỗi tầng nhà cao **`13 - 16` studs**, cửa cuốn Garage ô tô tối thiểu rộng **`14` studs × cao `10.5` studs** (vì xe GTA V rộng `8.2` studs, cao `6.95` studs!).

---

## 4. MẪU GIAO DIỆN MODULE CHUẨN (`src/shared/World/Modules/<TenFile>.luau`)

Mọi file đặt trong `src/shared/World/Modules/` phải trả về đúng bảng giao diện `WorldModuleSpec` sau để `DistrictRegistry.luau` tự động nạp:

```luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

local Module = {
	Id = "Plot_C1_LSCustoms",
	PlotId = "Plot_C1",
	Order = 20,
	Enabled = true,
}

function Module.build(modulesContainer: Instance): Instance
	local root = PartBuilder.folder("Plot_C1_LSCustoms", modulesContainer)

	-- Xoá tấm bê tông chờ mặc định của ô C1 nếu muốn lát sân riêng (hoặc xây trực tiếp từ cao độ Y = 1.15 trở lên!)
	-- Ví dụ tường gạch có máu ẩn 140 HP/viên (xe đụng hoặc súng bắn hết máu tự vỡ + sập dây chuyền hàng trên):
	PartBuilder.brickWall(
		root,
		"SouthFacadeBrickWall",
		Vector3.new(-218, 8.15, 118), -- Tâm bức tường
		Vector3.new(36, 14, 1.4),     -- Rộng 36, cao 14 (Y từ 1.15 đến 15.15), dày 1.4
		"X",
		6.0,                          -- Mỗi viên gạch dài 6 studs
		4,                            -- 4 hàng gạch chồng so le (StructuralRow 1..4)
		Color3.fromRGB(168, 76, 58),
		Enum.Material.Brick,
		140                           -- Máu ẩn PartHealth = 140 mỗi viên!
	)

	return root
end

return Module
```

---

## 5. LỆNH CẬP NHẬT `studio-sync.json` KHI ĐÃ GỘP NHIỀU NHÁNH VỀ `main`

Sau khi gộp các PR vào `main` (hoặc trên nhánh của bất kỳ Agent nào muốn đẩy trực tiếp sang Roblox Studio):
```bash
node -e 'const fs=require("fs"); const j=JSON.parse(fs.readFileSync("studio-sync.json","utf8")); j.actions=[]; fs.writeFileSync("studio-sync.json",JSON.stringify(j,null,2)+"\n");'
node bridge/publish.mjs \
  --action-file bridge/rebuild_world_action.luau \
  --action-desc "Đồng bộ toàn bộ Thành Phố + Xe + Các Công Trình Đa-Agent" \
  "chore(sync): compile combined multi-agent world bundle"
```

---

## 6. CÁC PROMPT MẪU COPY-PASTE CHO TỪNG TAB ARENA.AI SONG SONG

> ⚠️ **BẢN MỚI NHẤT (v3) đã chuyển sang file riêng: [`agents/WORKER_PROMPT_V3.md`](agents/WORKER_PROMPT_V3.md)**
> Bản v3 bổ sung 3 luật bắt buộc: đọc `docs/PERFORMANCE.md` (part nhỏ không va chạm, sàn/mái giữ va chạm),
> đọc `docs/UI_GUIDE.md` (đồng bộ bảng màu HUD mới), và nghiệm thu bằng **số liệu** (0 tràn biên ·
> 0 Z-fighting · 0 khối lơ lửng · ≥ 10 ảnh render). Prompt dưới đây chỉ giữ để tham khảo lịch sử.

Bạn chỉ cần copy nguyên văn từng khung dưới đây dán vào mỗi tab Arena.ai mới:

### 🔹 Tab Agent #1 — Garage Độ Xe Los Santos Customs (`Plot_C1`)
```text
(Nếu chưa thấy file `MULTI_AGENT_SYSTEM.md` trong repo, hãy chạy `git fetch origin && git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting` trước).
Hãy đọc kỹ `MULTI_AGENT_SYSTEM.md`, `src/shared/WorldGrid.luau`, `src/shared/World/PartBuilder.luau` và chạy `node bridge/agent-radio.mjs read` để xem tin nhắn từ các Agent phiên khác, sau đó chạy `node bridge/agent-radio.mjs say Plot_C1 "Nhận ô Plot_C1 xây Garage LS Customs"` để báo danh.

Nhiệm vụ của phiên này: Xây dựng DUY NHẤT 1 công trình cực kỳ chỉnh chu là **Garage Độ Xe Los Santos Customs** tại ô `Plot_C1` (vùng xây dựng lõi X từ -299 đến -137, Z từ -9 đến +123, mặt nền Y = 1.15).
Yêu cầu bắt buộc:
1. Chỉ tạo file module mới `src/shared/World/Modules/Plot_C1_LSCustoms.luau` (TUYỆT ĐỐI không sửa các file lõi chung và không commit đè `studio-sync.json` vào PR để 0% xung đột Git).
2. Kiến trúc công nghiệp chuẩn GTA V: Sân đỗ bê tông phía Nam nhìn ra Vespucci Blvd, 2 khoang cửa cuốn ô tô cao rộng (>= 15x11 studs để xe rộng 8.2 cao 7.0 chạy thẳng vào trong được!), bảng hiệu chữ nổi Neon "LOS SANTOS CUSTOMS", tường gạch ghép khối bằng `PartBuilder.brickWall` / `PartBuilder.box` có máu ẩn `integrity` (xe tông hoặc bắn hết máu tự vỡ!), cùng FULL nội thất bên trong (cầu nâng thuỷ lực 2 trụ, tủ đồ nghề đỏ, giá lốp xe, bàn thu ngân, đèn tuýp trần).
3. Kiểm thử cú pháp Luau bằng `@luau-rs/luau` và dựng ảnh 3D kiểm tra bằng mắt từ nhiều góc, sau đó dùng `node bridge/agent-radio.mjs say Plot_C1 "..."` báo lại toạ độ cổng xe ra vào cho các Agent khác biết rồi mở PR về nhánh `main`.
```

### 🔹 Tab Agent #2 — Siêu Thị Tiện Lợi 24/7 Supermarket (`Nửa Tây Plot_C3`)
```text
(Nếu chưa thấy file `MULTI_AGENT_SYSTEM.md` trong repo, hãy chạy `git fetch origin && git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting` trước).
Hãy đọc kỹ `MULTI_AGENT_SYSTEM.md`, `src/shared/WorldGrid.luau`, `src/shared/World/PartBuilder.luau` và chạy `node bridge/agent-radio.mjs read` để xem tin nhắn từ các Agent phiên khác, sau đó chạy `node bridge/agent-radio.mjs say Plot_C3_West "Nhận nửa Tây Plot_C3 xây Siêu thị 24/7"` để báo danh.

Nhiệm vụ của phiên này: Xây dựng DUY NHẤT 1 công trình cực kỳ chỉnh chu là **Cửa hàng tiện lợi 24/7 Supermarket** tại nửa Tây ô `Plot_C3` (giới hạn X từ +137 đến +212, Z từ +20 đến +123, mặt nền Y = 1.15, mặt tiền quay ra ngã tư Alta St & Vespucci Blvd).
Yêu cầu bắt buộc:
1. Chỉ tạo file module mới `src/shared/World/Modules/Plot_C3_Supermarket247.luau` (không sửa file chung, không chạm `studio-sync.json` trong PR).
2. Mặt tiền chuẩn 24/7 GTA V (mái hiên sọc Xanh Lá - Trắng - Đỏ Cam phát sáng, hệ vách kính lớn chia từng tấm kính rời có máu ẩn `integrity = 45` bắn vỡ từng ô, cửa đôi mở rộng cao 8.5 studs, bãi đậu xe có gờ chặn bánh phía trước).
3. Full nội thất bên trong cực chi tiết: Quầy thu ngân + máy tính tiền, máy ATM góc tường, 3 dãy kệ hàng đầy sản phẩm nhiều màu (cũng có máu ẩn bắn vỡ được!), tủ lạnh nước ngọt cửa kính phát sáng phía cuối tiệm, máy pha cà phê/Slushie.
4. Kiểm thử Luau + render 3D kiểm tra ngoại thất & nội thất, báo toạ độ lối vào qua `node bridge/agent-radio.mjs say Plot_C3_West "..."` rồi mở PR về `main`.
```

### 🔹 Tab Agent #3 — Đồn Cảnh Sát Mission Row LSPD (`Nửa Đông Plot_C3`)
```text
(Nếu chưa thấy file `MULTI_AGENT_SYSTEM.md` trong repo, hãy chạy `git fetch origin && git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting` trước).
Hãy đọc kỹ `MULTI_AGENT_SYSTEM.md`, `src/shared/WorldGrid.luau`, `src/shared/World/PartBuilder.luau` và chạy `node bridge/agent-radio.mjs read` để xem tin nhắn từ các Agent phiên khác, sau đó chạy `node bridge/agent-radio.mjs say Plot_C3_East "Nhận nửa Đông Plot_C3 xây Đồn Cảnh Sát Mission Row LSPD"` để báo danh.

Nhiệm vụ của phiên này: Xây dựng DUY NHẤT 1 công trình cực kỳ chỉnh chu là **Đồn Cảnh Sát Mission Row LSPD** tại nửa Đông ô `Plot_C3` (giới hạn X từ +222 đến +299, Z từ -9 đến +123, mặt nền Y = 1.15).
Yêu cầu bắt buộc:
1. Chỉ tạo file module mới `src/shared/World/Modules/Plot_C3_MissionRowLSPD.luau` (không sửa file chung, không chạm `studio-sync.json` trong PR).
2. Kiến trúc chuẩn LSPD: Bậc tam cấp sảnh chính, cột đá, bảng hiệu huy hiệu "LOS SANTOS POLICE DEPT — OBEY & SURVIVE", sân đáp trực thăng chữ H trên sân thượng, tường gạch & kính chia khối có máu ẩn `integrity`, cùng nội thất tầng trệt (quầy trực ban, dãy bàn làm việc thám tử, phòng giam song sắt thép phía sau).
3. Kiểm thử Luau + render 3D nhiều góc kiểm tra kỹ, báo toạ độ cổng chính qua `node bridge/agent-radio.mjs say Plot_C3_East "..."` rồi mở PR về `main`.
```

### 🔹 Tab Agent #4 — Tháp Tài Chính Maze Bank Tower (`Plot_D2`)
```text
(Nếu chưa thấy file `MULTI_AGENT_SYSTEM.md` trong repo, hãy chạy `git fetch origin && git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting` trước).
Hãy đọc kỹ `MULTI_AGENT_SYSTEM.md`, `src/shared/WorldGrid.luau`, `src/shared/World/PartBuilder.luau` và chạy `node bridge/agent-radio.mjs read` để xem tin nhắn từ các Agent phiên khác, sau đó chạy `node bridge/agent-radio.mjs say Plot_D2 "Nhận ô trung tâm Plot_D2 xây Tháp Maze Bank Tower"` để báo danh.

Nhiệm vụ của phiên này: Xây dựng DUY NHẤT 1 công trình biểu tượng cực kỳ chỉnh chu là **Tháp Tài Chính Maze Bank Plaza & Tower** tại ô trung tâm `Plot_D2` (giới hạn X từ -83 đến +83, Z từ -199 đến -63, mặt nền Y = 1.15, nhìn thẳng xuống Quảng trường Legion Square).
Yêu cầu bắt buộc:
1. Chỉ tạo file module mới `src/shared/World/Modules/Plot_D2_MazeBankTower.luau` (không sửa file chung, không chạm `studio-sync.json` trong PR).
2. Khối đế Plaza bậc thang + đài phun nước tiền sảnh + thân tháp vát góc thu dần lên đỉnh có bãi đáp trực thăng tròn "MAZE BANK" đỏ trắng trên nóc; sảnh tầng trệt thông tầng cao 18 studs có quầy lễ tân đá cẩm thạch, cổng an ninh, thang máy & các ô kính mặt dựng tầng thấp có máu ẩn `integrity` bắn vỡ được!
3. Kiểm thử Luau + render 3D kiểm tra cả tổng thể tháp lẫn cận cảnh sảnh tầng trệt, báo toạ độ sảnh qua `node bridge/agent-radio.mjs say Plot_D2 "..."` rồi mở PR về `main`.
```

### 🔹 Tab Agent #5 — Hạ Tầng Đèn Giao Thông, Đèn Đường & Hàng Cọ California (`StreetProps`)
```text
(Nếu chưa thấy file `MULTI_AGENT_SYSTEM.md` trong repo, hãy chạy `git fetch origin && git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting` trước).
Hãy đọc kỹ `MULTI_AGENT_SYSTEM.md`, `src/shared/WorldGrid.luau`, `src/shared/World/PartBuilder.luau` và ĐẶC BIỆT chạy `node bridge/agent-radio.mjs read` để xem toạ độ lối xe vào & chỗ đậu xe của tất cả các Agent khác nhằm chừa trống vỉa hè, sau đó chạy `node bridge/agent-radio.mjs say StreetProps "Nhận hạng mục Đèn giao thông, Đèn đường & Hàng cọ California"` để báo danh.

Nhiệm vụ của phiên này: Xây dựng hệ thống **Đèn Giao Thông Ngã Tư, Đèn Đường Cao Áp & Hàng Cây Cọ California Ven Biển** dọc mép vỉa hè.
Yêu cầu bắt buộc:
1. Chỉ tạo file module mới `src/shared/World/Modules/Infra_StreetLightsAndPalms.luau` (không sửa file chung, không chạm `studio-sync.json` trong PR).
2. Đặt trụ đèn tín hiệu Đỏ-Vàng-Xanh vươn cần ngang tại các ngã tư chính (mép vỉa hè Y = 1.15, tuyệt đối không lấn xuống lòng đường nhựa hay chặn cổng garage các ô đất), hàng cây cọ thân đốt cong nhẹ dọc đại lộ biển Vespucci Blvd & lối dạo biển, ghế đá & thùng rác công cộng — TẤT CẢ cột đèn, thùng rác, thân cọ đều gắn máu ẩn `integrity` để siêu xe đâm mạnh hoặc bắn sẽ gãy vỡ!
3. Kiểm thử Luau + render 3D kiểm tra không có bất kỳ cột nào nằm giữa đường chạy xe trước khi mở PR về `main`.
```
