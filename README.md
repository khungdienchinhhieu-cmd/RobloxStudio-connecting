# 🌴 Dự Án GTA V Roblox — Los Santos Modular (Destructible Edition)

Dự án tái hiện thế giới mở **Grand Theft Auto V (Los Santos)** trên Roblox Studio theo kiến trúc **ghép từng phần siêu chi tiết** và **kết cấu khối vật lý có thể phá huỷ (`Modular Destructible Voxels`)**.

> 🤖 **CHẠY NHIỀU PHIÊN ARENA.AI SONG SONG (MULTI-AGENT)?**  
> Đọc ngay **[`MULTI_AGENT_SYSTEM.md`](./MULTI_AGENT_SYSTEM.md)** và bảng phân công **[`agents/AGENT_TASK_BOARD.json`](./agents/AGENT_TASK_BOARD.json)**! Mọi công trình độc lập được đặt tại `src/shared/World/Modules/<TenModule>.luau` và được `DistrictRegistry.luau` tự động nạp vào thành phố với **0% xung đột Git**.

---

## ⚠️ 3 Nguyên Tắc Thiết Kế Bắt Buộc (Luôn Tuân Thủ)

1. **MỘT CÔNG TRÌNH MỘT LẦN — CỰC KỲ CHỈNH CHU:**
   - Tuyệt đối **không** dựng hàng loạt 5–6 căn nhà sơ sài trong một lượt.
   - Khi sang phần công trình, **mỗi bước chỉ tập trung làm đúng 1 công trình duy nhất** nhưng đạt độ chi tiết cao nhất (tỷ lệ kiến trúc thật, phào chỉ, bậc tam cấp, khung cửa, ánh sáng, nội thất).
2. **KẾT CẤU GHÉP KHỐI CHO CƠ CHẾ PHÁ HUỶ (`VoxelBuilder.luau`):**
   - Toàn bộ hạng mục nổi trên mặt đất (dải phân cách bê tông Jersey, tường chắn đá, bồn cây xây gạch, cọc chắn vỉa hè, lan can bờ biển, bậc thềm, và mọi tòa nhà về sau) đều được ghép từ **các viên/khối vật lý độc lập** có gắn sẵn thuộc tính:
     - `Destructible = true`
     - `MaxIntegrity` & `Integrity` (độ bền chịu lực va chạm / vụ nổ)
     - `FractureGroup` (nhóm kết cấu để tính sập mảng tường / bung gạch)
   - Chỉ riêng cốt nền địa chất và mặt nhựa đường chính giữ `Destructible = false` để xe và người chơi không rơi xuyên đáy bản đồ.
3. **TEST TRÊN BROWSER TRƯỚC KHI ĐƯA VÀO ROBLOX STUDIO:**
   - Sau mỗi phần, chạy thực thi trực tiếp mã Luau trong máy ảo để kết xuất ảnh 3D đa góc độ (Toàn cảnh, Cận cảnh mặt đường/bờ biển/đồi núi, Giao diện HUD) và cập nhật trình mô phỏng trên Browser kiểm tra thật ưng ý rồi mới đồng bộ sang Studio.

---

## 🗺️ Quy Hoạch Bản Đồ Đối Xứng (`WorldGrid.luau` — `1 160 × 1 160 studs` · **tỉ lệ 1:1 ngoài đời**)

> **Thước đo chuẩn (từ `Sync v22`):** `1 m = 3,33 stud` (1 stud = 0,30 m). Mọi kích thước đều suy ra từ hằng số
> `WorldGrid.STUDS_PER_METER` — **không đặt số stud tuỳ hứng nữa**.
> Đại lộ 4 làn = **48 stud (14,4 m)** · đại lộ 2 làn = **40 stud (12 m)** · vỉa hè = **14 stud (4,2 m)** · tầng nhà = **11 stud (3,3 m)**.

| Mã Khu | Tên Khu Vực (Los Santos) | Tọa độ X (`studs`) | Tọa độ Z (`studs`) | Kích thước thật | Trạng thái |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **North Ridge** | **Vinewood Hills** (Đồi vát nghiêng tự nhiên, vách đá & tường chắn ghép khối) | `[-580, +580]` | `[-380, -244]` | 348 × 41 m | ✅ Hoàn thành ở Nền v2 |
| **Plot E1** | **Pacific Bluffs** — biệt thự ven vịnh (bản "ít part" đã **gỡ** ở v23, chờ dựng lại **chi tiết** như LS Customs) | `[-536, -358]` | `[-204, -60]` | 53 × 43 m | ☐ **Trống — Agent 3 vòng 2** |
| **Plot D1** | **Rockford Hills — Luxury Autos** (`3 165` part, `99,6%` máu ẩn, kính cong xe tông xuyên) | `[-318, -134]` | `[-204, -60]` | 55 × 43 m | ✅ Nghiệm thu 9,1/10 — **Sync v26** |
| **Plot D2** | **Pillbox Hill** — **Tháp Maze Bank** (`2 312` part, `99.1%` máu ẩn) | `[-86, +86]` | `[-204, -60]` | 52 × 43 m | ✅ Nghiệm thu 9.2/10 — **Sync v22** |
| **Plot D3** | **Downtown Vinewood** (Ô móng kỹ thuật sạch chờ công trình) | `[+134, +318]` | `[-204, -60]` | 55 × 43 m | ⏳ Chờ dựng từng công trình |
| **Plot E2** | **La Mesa** (trống — chờ Agent, Giai đoạn 4) | `[+358, +536]` | `[-204, -60]` | 53 × 43 m | ☐ |
| **Plot E3** | **Little Seoul** (trống — chờ Agent, Giai đoạn 4) | `[-536, -358]` | `[-12, +128]` | 53 × 42 m | ☐ |
| **Plot C1** | **Del Perro — Los Santos Customs** (`3 462` part, `98.1%` máu ẩn, 2 khoang độ xe thật `[E]`) | `[-318, -134]` | `[-12, +128]` | 55 × 42 m | ✅ Nghiệm thu v10 — **Sync v22** |
| **Plot C2** | **Legion Square** (Quảng trường bậc cấp, hồ nước & tường gạch ghép khối) | `[-86, +86]` | `[-12, +128]` | 52 × 42 m | ✅ Hoàn thành ở Nền v2 |
| **Plot C3** | **Mission Row** (Nửa Tây: Siêu thị 24/7 `934` part • Nửa Đông: **Đồn LSPD `4 639` part**) | `[+134, +318]` | `[-12, +128]` | 55 × 42 m | ✅ Cả 2 nửa — **Sync v22** |
| **Plot E4** | **Richman Glen** (trống — chờ Agent, Giai đoạn 4) | `[+358, +536]` | `[-12, +128]` | 53 × 42 m | ☐ |
| **South Coast** | **Vespucci Beach** (Kè đá ghép khối, cầu thang xuống biển, sàn gỗ, kè chắn sóng) | `[-580, +580]` | `[+168, +380]` | 348 × 64 m | ✅ Hoàn thành ở Nền v2 |

> 🛎️ **Từ `Sync v25` — MỖI Ô ĐẤT CÓ ÍT NHẤT MỘT CHỨC NĂNG DÙNG ĐƯỢC.** Quầy dịch vụ đặt ngay trước cửa
> công trình (suy từ toạ độ cửa thật, không đoán): C1 🔧 sửa xe $250 · C3W 🥤 snack $25 / 🛡️ giáp $250 /
> 🔫 tiếp đạn $150 · C3E 🚔 bảo lãnh 500×sao / 🔓 mở kho vũ khí · D2 🏦 nạp / rút tiền · C2 🏁 chạy thử xe ·
> D1 🏎️ showroom $2 000 · D3 🎬 rạp $50 · E1 💆 spa $400 · E2 🚗 garage $150 · E3 🍜 quán ăn $20 (+50 máu)
> · E4 🛍️ TTTM $350. Ô chưa dựng thì quầy hiện "CHỜ DỰNG" và **tự bật** khi agent nạp module.
> Xem bản đồ kiểm tra: `/services` (hoặc `/api/services` lấy JSON).

**9 đại lộ (đo lại 1:1):**

| Đại lộ | Hướng | Trục | Rộng | Quy đổi |
| :--- | :---: | :---: | :---: | :---: |
| Vinewood Blvd · Olympic Fwy · Vespucci Blvd | Đông–Tây | `Z = −224 / −36 / +148` | 40 / **48** / 40 stud | 12 / **14,4** / 12 m |
| Pacific Coast Hwy · Del Perro Fwy · San Andreas Ave | Bắc–Nam | `X = −556 / −338 / −110` | 40 / 40 / **48** stud | 12 / 12 / **14,4** m |
| Alta St · Elgin Ave · La Mesa Ave | Bắc–Nam | `X = +110 / +338 / +556` | **48** / 40 / 40 stud | **14,4** / 12 / 12 m |

---

## 📋 Lộ Trình Triển Khai Từng Bước Nhỏ

- [x] **Bước 1: GTA V HUD (Phím `[H]` mở Menu Test) + Đại Tu Toàn Bộ Nền Thành Phố Ghép Khối (`2,803` parts)**
- [x] **Bước 2 (Hiện tại): Hệ thống Xe Hơi GTA V + Máu Ẩn Cho Từng Part (`PartHealth`) & Tự Vỡ Khi Xe Đụng / Bị Bắn**
  - **Máu Ẩn Từng Khối (`PartBuilder.luau` + `DestructionManager.luau`):** Mọi viên gạch, đốt dải phân cách K-Rail, cọc tiêu thép, bờ kè đá, tượng đài và **từng bộ phận vỏ xe** (cản trước/sau, nắp capo, kính chắn gió, 2 cửa xe, đèn pha/hậu, cánh gió) đều có máu ẩn `PartHealth`. Khi bị xe tông hoặc súng bắn sẽ sẫm màu/nứt dần và **tự động vỡ tung thành mảnh vật lý văng ra** ngay khi hết máu ẩn (kèm sập dây chuyền các viên gạch phía trên).
  - **Xe Hơi GTA V Cao Thoáng + Full Nội Thất Cockpit + Diễn Hoạt Mở Cửa `[F]` (`VehicleBuilder.luau` + `VehicleManager.luau`):** Dòng Coupe thể thao `Banshee GT` & Muscle `Gauntlet GTX` nâng cao trần ca-bin (`~5.68` studs), trang bị **28+ chi tiết nội thất** (vô lăng 3 chấu đáy phẳng + lẫy số, chân ga/phanh, đồng hồ phát sáng, màn hình GPS, 4 cửa gió điều hoà, bệ trung tâm + cần số + phanh tay + khay cốc, ghế đua 2 tông màu có gối tựa đầu thanh crôm, gương hậu trong + che nắng + đèn trần tự sáng khi mở cửa) và **khớp bản lề cửa thực (`LeftDoorHinge`/`RightDoorHinge`) mở xoay `64°` mượt mà khi bấm `[F]` lên/xuống xe**!
  - **Súng Kiểm Thử Phá Huỷ (`WeaponManager.luau` + `WeaponClient.luau`):** Trang bị sẵn `Pistol 9mm` & `Carbine Rifle` có tâm ngắm chấm trắng chuẩn GTA V, tia đạn và hiệu ứng bắn vỡ từng viên gạch / kính xe / cánh cửa xe.
- [ ] **Bước 3: Hạ tầng Đường phố (Đèn giao thông ngã tư, Đèn đường đôi & Hàng cọ California — có máu ẩn, xe tông gãy đổ)**
- [x] **Bước 4: Công trình #1 — Garage Độ Xe Los Santos Customs (`Plot C1` — `3,462` khối ghép rời, `98.1%` có máu ẩn)**
  - **Nghiệm thu đợt 2 (v10 — vá 3 phản hồi của Chủ dự án):**
    1. **Hết khối chồng lên nhau:** `WestYardSlab` / `EastYardSlab` bị lát trùm `Z = -7.5..+121.5` đè lên 35 ô sân trước (`Y` lệch `0.03` -> nhấp nháy Z-fighting) → **cắt còn `Z = -7.5..+51.2`** (chỉ lát sân hông phía Bắc); `EastPalletRack` là 1 khối đặc `2×8×9` bị 3 thùng gỗ xuyên qua → **thay bằng giá kệ sắt HỞ 4 chân + 3 dầm ngang + thùng gỗ nằm trên dầm**; vết dầu & mặt bàn quầy lễ tân cũng được tách cao độ `>= 0.03` -> **`0` cặp mặt phẳng trùng cao độ** (đo tự động).
    2. **Bớt rối mắt:** sân trước rút từ **189** vật dụng lặt vặt xuống còn **~60**; jitter bê tông giảm `10 → 2` (màu sàn đồng nhất thay vì loang lổ); bỏ dòng chữ `"CUSTOMS"` sơn chồng lên logo `"LSC"`; chỉ còn **3 cọc tiêu thẳng hàng trước 3 trụ nhà**, **1 băng ghế** dưới mái hiên, **2 chậu cây đối xứng** 2 bên cửa đi bộ và **2 mũi tên vàng** dẫn làn vào 2 khoang.
    3. **CÓ CHỨC NĂNG THẬT (không còn là mô hình trang trí):**
       - `src/shared/World/Modules/Plot_C1_LSCustoms.luau` dựng thêm **`BayZone1` / `BayZone2`** (vùng quét xe `19.3 × 13 × 46` trong mỗi khoang), **dải LED neon mặt sàn + đèn cầu** ở ngưỡng cửa cuốn (ĐỎ = trống / XANH = có xe) và bảng `MOD SHOP`.
       - `src/server/LSCustomsService.luau` (mới): quét `0.35s/lần` để biết khoang nào có xe, bật đèn XANH, gửi thông báo `"Xe đã vào Khoang N — bấm [E] để độ xe!"`, và xử lý **3 dịch vụ**: **SỬA CHỮA `$250`** (hồi 100% `PartHealth` mọi chi tiết + `EngineHealth` + sơn lại màu gốc), **SƠN LẠI `$500`** (đổi màu vỏ theo 8 màu GTA V, lưu luôn màu gốc mới), **TURBO `$1,500`** (`+8 MaxSpeed`/cấp, tối đa 3 cấp = `+24`). Server kiểm tra tiền & cấp Turbo, chống spam `0.5s`.
       - `src/client/UI/LSCustomsUI.luau` (mới): chip **`[E] ĐỘ XE`** nhỏ sát đáy màn hình (không che nhân vật) + bảng độ xe chuẩn GTA V (phím `[1] [2] [3]`, `[ESC]` đóng), hiển thị tên xe / % hư hỏng / cấp Turbo / giá tiền và phản hồi thành công–thất bại.
       - **Kiểm thử tương tác trên browser:** mở **`/lscustoms`** trên server `:8080` (`bridge/lscustoms-demo.html`) để bấm thử đủ 3 dịch vụ, xem đèn ĐỎ→XANH và trừ tiền thật; **17/17** test logic DOM đều PASS.
  - Ảnh nghiệm thu: [`docs/qa/plot_c1_forecourt_topdown.png`](docs/qa/plot_c1_forecourt_topdown.png), [`docs/qa/plot_c1_east_corner.png`](docs/qa/plot_c1_east_corner.png), [`docs/qa/plot_c1_south_facade.png`](docs/qa/plot_c1_south_facade.png), [`docs/qa/plot_c1_bay_lights.png`](docs/qa/plot_c1_bay_lights.png)
- [x] **Bước 4.5: ĐẠI TU UI/HUD + VÒNG CHỌN SÚNG CHUẨN GTA V (Sync v12)** ✅
  - **Vòng chọn súng (`src/client/UI/GtaWeaponWheel.luau`, mới — `~620` dòng):** giữ **`TAB`** mở vòng 8 ô (Tay không · Gậy bóng chày · Pistol 9mm · AP Pistol · Micro SMG · Carbine Rifle · Assault Shotgun · Sniper Rifle), ô 1 ở **trên cùng** đi thuận chiều kim đồng hồ; rê chuột để chọn (vùng chết < 54px giữ nguyên ô), thả `TAB` để trang bị, `ESC` huỷ, phím **`1–8`** đổi nhanh khi vòng đóng. Ô đang chọn phóng `1.09×`, viền accent theo loại súng, tâm hiện **danh mục + tên súng + đạn**. Toàn bộ icon súng vẽ bằng `Frame` (không cần asset).
  - **Arsenal thật (`WeaponManager.luau` v2):** 8 vũ khí có **đạn thật** (băng/dự trữ), `[R]` nạp đạn theo thời gian nạp riêng từng khẩu; shotgun bắn **8 viên tản** (spread `6.5°`), sniper `160` sát thương tầm `900`, AP Pistol/Micro SMG/Carbine bắn tự động, gậy bóng chày chém cận chiến `34`. Server giữ trạng thái đạn và đồng bộ qua remote `WeaponSync`; client vẽ **3 tia loe** cho shotgun và vệt chớp trắng khi chém.
  - **HUD đẹp hơn (`GtaHud.luau`):** radar bo góc `10px` + viền kính trong; 3 thanh **Máu / Giáp / Thể lực xếp chồng** (5px, bo 3px) thay vì nằm ngang; cụm tiền có **panel kính mờ + vạch accent xanh**; sao truy nã có nền kính; đồng hồ tốc độ có panel + vạch accent; feed box bo góc; Menu Test `[H]` bo góc + gradient header + hiệu ứng hover; thêm chip nhắc **`[TAB] VŨ KHÍ`**.
  - **Thẻ vũ khí góc dưới phải:** tên súng + **đạn trong băng / dự trữ** cỡ lớn, viền accent đổi màu theo súng, hiện `[R] NẠP ĐẠN` đỏ khi hết đạn; tự ẩn khi tay không hoặc đang lái xe.
  - **Kiểm thử:** demo tương tác thật trong browser tại **`/hud`** (`bridge/hud-demo.html`) + **`33/33` test logic DOM PASS** (`/tmp/hud_test.mjs`): ánh xạ 8 hướng chuột → 8 ô, vùng chết, mở/đóng vòng, trang bị đúng ô, đạn giảm/nạp, class `equipped`, sao truy nã.
  - Tài liệu thiết kế dùng chung cho các Agent: [`docs/UI_GUIDE.md`](docs/UI_GUIDE.md).
- [x] **Bước 5: Công trình #2 — Cửa hàng Tiện lợi 24/7 Supermarket (`Plot C3` — full nội thất kệ hàng & kính vỡ từng mảnh)** ✅ *(xong — `AGENT_2` `52d0eff`, nghiệm thu ĐẠT: `934` khối, `99,9 %` phá huỷ, `0` khối tràn biên/Z-fighting/lơ lửng; biên bản: [`agents/notes/APPROVED_AGENT_2_SUPERMARKET_247__b37b6115.md`](agents/notes/APPROVED_AGENT_2_SUPERMARKET_247__b37b6115.md))*
  - `src/shared/World/Modules/Plot_C3_Supermarket247.luau`: mặt tiền 24/7 (mái hiên sọc xanh–trắng–cam phát sáng, bảng hiệu `46 × 4,4` stud, cột pylon), vách kính chia **từng ô rời có máu riêng** (bắn vỡ từng mảnh), cửa đôi `9` stud, bãi đỗ + gờ chặn bánh, cửa cuốn nhận hàng `16 × 12` + dock nâng.
  - Nội thất full: 3 dãy kệ hàng đầy sản phẩm, quầy thu ngân + máy tính tiền, ATM, tủ lạnh nước ngọt phát sáng, máy Slushie.
  - Ảnh nghiệm thu: [`01_hero_southeast`](agents/reviews/Plot_C3_Supermarket247/01_hero_southeast.jpg), [`06_interior_from_door`](agents/reviews/Plot_C3_Supermarket247/06_interior_from_door.jpg), [`09_interior_aisles`](agents/reviews/Plot_C3_Supermarket247/09_interior_aisles.jpg), [`10_interior_coolers`](agents/reviews/Plot_C3_Supermarket247/10_interior_coolers.jpg)
  - **Tối ưu hiệu năng đi kèm (Sync v11):** lớp `src/shared/World/PerfOptimizer.luau` + tách nhịp cập nhật HUD/radar + cache server — xem [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md).
- [x] **Bước 6: Công trình #3 — Đồn Cảnh Sát Mission Row LSPD (`Plot C3`)** ✅ *(xong — `AGENT_3` `fb6a68f`, nghiệm thu ĐẠT **9.0/10**: `4 639` khối, `99,59 %` phá huỷ, `0` tràn biên/trùng/lơ lửng, `0` z-fighting nhìn thấy được, vỏ công trình kín; biên bản: [`MASTER_QA__b37b6115.md`](agents/reviews/AGENT_3_MISSION_ROW_LSPD/MASTER_QA__b37b6115.md))*
  - `src/shared/World/Modules/Plot_C3_MissionRowLSPD.luau`: khối 2 tầng `50 × 66` stud, mặt tiền trụ gạch ốp + **5 vịnh cửa sổ** mỗi tầng, dải chữ nổi **"LOS SANTOS POLICE DEPT"** và khẩu hiệu **"OBEY & SURVIVE"**, 2 huy hiệu LSPD tròn.
  - Nội thất tầng trệt: quầy trực ban xanh + vách kính giao dịch + cột dây xếp hàng, bullpen bàn thám tử, hành lang phòng giam song sắt; tầng 2 có phòng họp và sân thượng.
  - Sân thượng: **sân đáp trực thăng chữ H** (vòng tròn 96 mảnh, 8 đèn tiếp cận, lan can + gờ chắn chân, 4 đèn hiệu đỏ/xanh, chong chóng gió, cửa sập mái).
  - Ngoại thất: bậc tam cấp, cửa đôi `8 × 9` stud, cửa cuốn **Sally Port `18 × 12`** mặt Đông, bãi đỗ xe cảnh sát 3 ô có vạch kẻ, cột cờ, barrier, trụ nước cứu hoả, chữ "POLICE" trên mặt đường.
  - Agent Chính vá **7 chỗ** trước khi duyệt: khe hở góc Nam (`wallWithOpenings` dùng `IN_Z1 - WT`), sàn sân trước, mái, 2 cụm bụi cây z-fighting, vòng đáp trực thăng.
  - Ảnh nghiệm thu: [`01_facade_front`](agents/reviews/AGENT_3_MISSION_ROW_LSPD/01_facade_front.png), [`07_lobby_interior`](agents/reviews/AGENT_3_MISSION_ROW_LSPD/07_lobby_interior.png), [`13_roof_helipad`](agents/reviews/AGENT_3_MISSION_ROW_LSPD/13_roof_helipad.png), [`15_parking`](agents/reviews/AGENT_3_MISSION_ROW_LSPD/15_parking.png)
- [x] **Bước 7: Công trình #4 — Tháp Tài Chính Maze Bank Tower (`Plot D2`)** ✅ *(xong — `AGENT_4`, nghiệm thu **DUYỆT 9.2/10** (nộp 8.2): `2 312` khối, `2 270` khối có máu ẩn (`98,18 %`), `0` tràn biên / trùng lặp / z-fighting nhìn thấy được / lơ lửng; `6/6` khu vực đi lại được với bán kính nhân vật `1,0` stud; biên bản: [`agents/reviews/AGENT_4_MAZE_BANK_TOWER/MASTER_QA__b37b6115.md`](agents/reviews/AGENT_4_MAZE_BANK_TOWER/MASTER_QA__b37b6115.md))*
  - `src/shared/World/Modules/Plot_D2_MazeBankTower.luau` (`~106 KB`): tháp tài chính `166 × 136 × 300+` stud, **vách kính cong 6 tầng** ghép từng ô kính rời có máu riêng, **mái giật cấp 3 tầng** kiểu Maze Bank, 2 cánh tháp phụ, sảnh chính 2 tầng thông thuỷ với **trần gương + đèn chùm**, quầy giao dịch, thang cuốn + thang bộ, bãi đỗ ngầm, quảng trường đá granite có **đài phun nước** và hàng cọ.
  - Sân thượng có **sân đáp trực thăng `H`**, đèn tiếp cận, lan can kính, và tầng kỹ thuật. Mặt tiền có **logo Maze Bank phát sáng** + chữ nổi `MAZE BANK` cao gần `20` stud đọc được từ xa.
  - Agent Chính vá **4 chỗ** trước khi duyệt: 4 vách góc Nam dùng `IN_Z1 - WT` để lại **khe hở thẳng đứng** (đã đổi sang `IN_Z1`), **sân quảng trường loang lổ** (2 tông xám chênh `8` bậc -> về 1 tông `CONCRETE`), **khe hở 0,34 stud** giữa các phiến lát sân (`-> 0,07`), **khe hở 0,30 stud** giữa các tấm boong mái (`-> 0,07`).
  - Ảnh nghiệm thu: [`01_south_facade_hero`](agents/reviews/AGENT_4_MAZE_BANK_TOWER/01_hero_south_facade.jpg), [`07_interior_lobby_to_desk`](agents/reviews/AGENT_4_MAZE_BANK_TOWER/07_interior_lobby_to_desk.jpg), [`13_roof_helipad`](agents/reviews/AGENT_4_MAZE_BANK_TOWER/14_roof_helipad.jpg)
- [x] **Bước 8: VŨ KHÍ HẠNG NẶNG — SÚNG PHÓNG LỰU RPG-7 (`WeaponManager.luau` + `GtaWeaponWheel.luau`)** ✅
  - **Ô số 9 của vòng chọn súng:** vòng nâng từ `8 -> 9` ô, góc tự giãn `45° -> 40°`, **phím tắt `[9]`**, icon ống phóng + đầu đạn đỏ vẽ bằng `Frame`. Danh mục `VŨ KHÍ HẠNG NẶNG`, accent đỏ `#EF4444`.
  - **Đạn thật:** `SPECS.RPG` — sát thương trực tiếp `320`, hồi chiêu `1,75 s`, tầm `520`, **băng `1` viên / dự trữ `6`**, nạp `3,4 s`. Rocket là **part bay thật `145` stud/s** có vệt lửa neon, dò tia từng frame nên bắn trúng bất cứ thứ gì trên đường bay.
  - **Nổ diện rộng `explodeAt()`:** gọi `DestructionManager.damageRadius(center, 22, 260, 120)` -> **mọi khối trong bán kính `22` stud nhận tới `260` sát thương** và văng theo lực `120`; người trong bán kính nhận `260 × 0,35` giảm dần theo khoảng cách (`0,4–1,0` hệ số); kèm **cầu lửa + sóng xung kích + mảnh văng** trong `LosSantos_Debris` và tự dọn sau vài giây.
- [x] **Bước 9: NPC PHẢN ỨNG — Dân phố Los Santos biết trả đũa (`src/server/NPCManager.luau`)** ✅
  - **6 tính cách NPC:** `CIVILIAN` (dân thường) · `BUSINESS` (doanh nhân) · `TOURIST` (khách du lịch) · `GANGSTER` (đầu gấu có súng) · `BRAWLER` (dân anh chị tay bo) · `COP` (cảnh sát LSPD). Mỗi NPC là **rig R6 đầy đủ** (đầu, tóc, mắt, thân, 2 tay, 2 chân nối bằng `Motor6D`), có gắn bảng tên nổi và thanh máu.
  - **4 phản ứng khi bị tấn công** (bốc thăm có trọng số theo tính cách + loại đòn + % máu còn lại):
    1. **`🔫 BẮN TRẢ`** — rút súng ngắn ra, chĩa về phía người chơi và bắn theo nhịp (chỉ GANGSTER & COP).
    2. **`🏃 CHẠY TRỐN`** — quay đầu bỏ chạy khỏi chỗ bị đánh, chạy càng hung khi máu càng thấp.
    3. **`📱 QUAY VIDEO / GỌI 911`** — rút điện thoại ra quay, **tăng `WantedLevel` (tối đa 5) trong 90 giây** và **điều tối đa 2 cảnh sát đang sống tới ứng cứu** (chuyển sang trạng thái `BẮN TRẢ`).
    4. **`👊 ĐÁNH TAY KHÔNG`** — lao vào đấm người chơi (BRAWLER gần như luôn chọn cách này).
  - **Bị đạn vs bị đấm vs bị nổ cho kết quả khác nhau:** trúng đạn `+35 %` xu hướng bỏ chạy, `+60 %` xu hướng gọi cảnh sát; bị đấm `+80 %` xu hướng đánh tay không; **dính bom RPG thì `+90` điểm bỏ chạy** cho toàn bộ NPC trong bán kính. Máu dưới `35 %` cộng thêm `70` điểm bỏ chạy; **cảnh sát không bao giờ bỏ chạy**.
  - **Tích hợp vũ khí:** `WeaponManager` gọi `NPCManager.notifyAttacked(model, player, "BULLET"/"MELEE")` khi đạn/đòn cận chiến trúng NPC, và `notifyExplosion(center, radius, player)` khi rocket nổ.
  - **NPC tự sinh trên phố:** `NPCManager.init()` dựng folder `LosSantos_NPCs` và **thả 14 NPC** rải ở 4 khu vực trung tâm (giới hạn `26` NPC cùng lúc), tự dò mặt đất bằng tia ngược từ `Y = 90` xuống.
  - **Kiểm thử:** ma trận phản ứng chạy `4 000` lần cho mỗi ô (`6` tính cách × `3` loại đòn) — khớp `100 %` với thiết kế (vd `COP` + trúng đạn -> `BẮN TRẢ 93 %`; `BUSINESS` + trúng đạn -> `GỌI 911 70 %`; `BRAWLER` + bị đấm -> `ĐÁNH TAY KHÔNG 98 %`). Demo xem trực tiếp tại **`/npc`** (`bridge/npc-demo.html`) — bấm 3 nút để xem đủ 4 phản ứng + rocket nổ.
- [x] **Bước 10: THÀNH PHỐ SỐNG ĐỘNG — NPC ĐI KHẮP PHỐ + NPC LÁI XE + NPC CÓ ANIMATION (`Sync v19`)** ✅
  - **NPC rải khắp thành phố thay vì dồn cục:** điểm đi bộ được **sinh tự động từ `WorldGrid`** — quét vỉa hè của **cả 7 đại lộ** (`Vinewood`, `Olympic`, `Vespucci`, `Del Perro`, `San Andreas`, `Alta`, `Elgin`) -> **296 điểm**, chạy `spawnAmbient(46)` (trước là 14 NPC / 4 cụm). Trần NPC nâng `26 -> 74`. Tỉ lệ tính cách trên phố: dân thường `34 %`, khách du lịch `16 %`, doanh nhân `12 %`, cảnh sát `11 %`, đầu gấu `13 %`, anh chị tay bo `14 %`. Có kiểm tra **cách nhau tối thiểu 9 stud** nên không ai đứng chồng lên ai.
  - **Đi bộ XUYÊN thành phố:** đích đi bộ cũ chỉ cách chỗ đứng `12–34` stud (loanh quanh một góc phố). Đích mới lấy từ danh sách vỉa hè với khoảng cách **`60–300` stud** -> NPC đi qua nhiều đại lộ, băng ngã tư. Tới nơi thì **đứng nghỉ `2–6 s`** rồi mới chọn đích tiếp theo (không quay đầu giật cục).
  - **Chống kẹt đường:** nếu `5 s` mà không nhích được (kẹt tường, kẹt xe, kẹt đồ đạc) thì **tự đổi đích khác**; mỗi lần đi chỉ gọi `Humanoid:MoveTo` có tiết chế nên NPC không bị rung lắc.
  - **4 XE CÓ TÀI XẾ NPC** (folder `LosSantos_Traffic`): dùng lại `VehicleBuilder` (Banshee GT / Gauntlet GTX, 4 màu), chạy **2 tuyến vòng khép kín** — vòng trung tâm `Olympic ↔ Vespucci ↔ San Andreas ↔ Alta` và vòng vành đai ngoài `Vinewood ↔ Del Perro ↔ Elgin ↔ Vespucci`. Tốc độ `26–34` stud/s, **bám đúng làn đường** (đã kiểm chứng bằng harness: `0` bước lệch khỏi lòng đường, vòng lặp khép kín).
  - **Tài xế thật:** mỗi xe có 1 NPC **ngồi đúng ghế lái** (`DriverSeat`, tâm thân trên mặt ghế `1,12` stud -> đầu không đội mui), hàn `WeldConstraint` vào khung sườn nên chạy cùng xe. Bị bắn / bị nổ thì tài xế vẫn phản ứng: **bỏ chạy -> xe tăng tốc**, **chết -> xe khựng lại và dừng**.
  - **8 TƯ THẾ ANIMATION** (`NPCAnimator.luau`, chạy ở **client**): `IDLE` (thở + liếc nhìn) · `WALK` (sải chân vung tay) · `RUN` (chúi người, dùng khi chạy trốn) · `SHOOT` (hai tay nâng súng + giật lùi) · `PUNCH` (đấm liên hoàn) · `PHONE` (giơ điện thoại quay video) · `DRIVE` (đùi gập, tay đặt vô lăng) · `DEAD` (ngã gục).
  - **Vì sao animation ở client:** server chỉ đổi đúng **1 attribute `AnimState`**; client xoay `Motor6D.Transform` của rig ở `24 Hz`, **bán kính hiển thị `260` stud** (xa hơn thì bỏ qua). Nhờ vậy 50 NPC chuyển động **không tốn thêm băng thông** và **không giành `C0` với server** (`Transform` là thuộc tính cục bộ, không replicate).
- [x] **Bước 11: BẢN ĐỒ RỘNG GẤP 1,6 LẦN + NPC MODEL ROBLOX + KỸ THUẬT NHÀ ÍT PART (`Sync v21`)** ✅
  - **Bản đồ: 720 → 1 120 stud chiều ngang (−360..+360 hẹp → −560..+560).** Thêm **2 đại lộ Bắc–Nam mới** `Pacific Coast Hwy (X = −540)` và `La Mesa Ave (X = +540)`; 3 đại lộ Đông–Tây kéo dài từ `±340` → `±560`. **4 ô đất mới** (`Plot_E1..E4`, mỗi ô 180 × 150/154 stud) khít tuyệt đối với vỉa hè cũ nên 4 công trình đã nghiệm thu **không dịch một stud nào**. Nền đồi Vinewood / bãi biển / vỉnh đều tự giãn theo `WorldGrid.MAP_WIDTH`.
  - **NPC dùng MODEL ROBLOX THẬT (R15):** module mới `NPCAppearance.luau` gọi `Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)` → nhân vật **đủ 15 khớp** đúng chuẩn Roblox, không còn rig R6 tự ghép. Chỉ dựng **4 mẫu** rồi `:Clone()` + sơn lại màu (7 tông da × 9 màu áo × 5 màu quần × 4 màu giày) → mỗi NPC một kiểu.
  - **NPC CÓ ANIMATION ĐI BỘ THẬT:** `Animator:LoadAnimation` với 3 animation gốc của Roblox (idle `507766666` · walk `507777826` · run `507767714`), tự `Play`/`Stop` theo trạng thái, và **`AdjustSpeed` theo tốc độ thật** (`WalkSpeed/16`) nên chân bước khớp quãng đường — không còn "trượt băng". Animation là của Roblox nên **mọi người chơi đều thấy**, không cần replicate từng khung hình.
  - **NPC MANG SKIN CỦA NGƯỜI CHƠI:** mỗi khi có người vào game, hệ thống lấy `Humanoid:GetAppliedDescription()` của chính họ rồi dựng một **bản sao y hệt** (kể cả phụ kiện, áo quần, khuôn mặt) thả xuống vỉa hè cách họ `40–160` stud. Chat Output: `[NPC] Đã thả bản sao của <tên> vào thành phố`.
  - **Nhiều NPC hơn:** `MAX_NPCS 74 → 150`, ambient `46 → 84`, xe có tài xế `4 → 8`. Điểm đi bộ sinh tự động nay là **9 đại lộ → 344 điểm** thay vì 296.
  - **★ KỸ THUẬT "NHÀ ÍT PART MÀ VẪN BỂ":** module mới `DestructibleShell.luau` chia công trình thành **4 tầng** — kết cấu chịu lực (~14 part) · **tấm vỏ = 1 ô cửa sổ** (~52 part) · **hoa văn gạch/ngói bằng `Texture` (0 part)** · trang trí (~9 part). Kèm đó `DestructionManager.fractureWorldBlock` được nâng cấp: **số mảnh vỡ tự co giãn theo kích thước khối** (viên gạch → 2 mảnh, tấm tường → 10–14 mảnh, chia theo lưới 3D). Kết quả đo bằng harness: **176 part (so với 3 462 của LS Customs) = −94,9 %**, mà phá sạch vẫn sinh **894 mảnh vỡ**. Chi tiết đầy đủ: [`docs/DESTRUCTIBLE_BUDGET.md`](docs/DESTRUCTIBLE_BUDGET.md).
  - **Công trình mẫu:** **Biệt thự Pacific Bluffs** (`Plot_E1`) — 3 tầng, 44 × 28 stud. ⚠️ **Đã gỡ ở `Sync v23`** vì kiểu "ít part" nhìn không đẹp bằng công trình chi tiết; kỹ thuật vẫn giữ trong `DestructibleShell.luau` cho khối vỏ phá huỷ, `Plot_E1` chờ Agent dựng lại **biệt thự chi tiết**.
- [x] **Bước 12: TỈ LỆ 1:1 VỚI NGOÀI ĐỜI — ĐƯỜNG & MỌI THỨ ĐÚNG KÍCH THƯỚC THẬT (`Sync v22`)** ✅
  - **Vấn đề:** sau khi mở rộng bản đồ, mặt đường vẫn 32–36 stud (9,6–10,8 m) trong khi xe rộng 7,1 stud (2,1 m) → nhìn như **đường hẻm**, không ra đại lộ.
  - **Chuẩn mới:** `WorldGrid.STUDS_PER_METER = 3.33` (1 stud = 0,30 m, khớp chiều cao nhân vật R15 ~5 stud ≈ 1,65 m) + helper `WorldGrid.meters(m)`. **Mọi** con số kích thước suy ra từ đây.
  - **Đường rộng đúng luật:** 4 làn → **48 stud (14,4 m)**, 2 làn + làn đỗ → **40 stud (12 m)**; vỉa hè **9 → 14 stud (4,2 m)**. Xe 7,1 stud vẫn chiếm ~60 % bề rộng làn → đúng tỉ lệ thật.
  - **Lưới lại toàn bộ:** bản đồ 1 120 → **1 160 stud (±580)**; 10 ô đất xếp **khít tuyệt đối** với mép đường (gap = **0,000 stud**, kiểm bằng script); ô đất 52–55 m × 42–43 m — đúng cỡ block downtown Los Santos.
  - **Không sửa tay 3 module công trình 3 000–4 600 dòng:** thêm `WorldGrid.RELOCATION` + `DistrictRegistry.applyRelocation()` — dựng xong rồi biến đổi cả model `X' = (X − oldCX)·k + newCX`, giữ nguyên trục Y (tầng vẫn 3,3 m). Harness xác nhận cả **3 công trình** (LS Customs, Maze Bank, LSPD + Supermarket) sau khi dời **vẫn nằm trọn trong ô đất mới**.
  - **Hết hardcode:** chỗ chia đôi `Plot_C3` (trước ghi cứng `217.5 / 218.5`) nay đọc tâm ô đất từ `WorldGrid.PLOTS`; 2 dải vỉa hè vành đai (trước ghi cứng `X = ±350` → rơi vào lòng đường Elgin mới) nay suy ra từ mép đại lộ ngoài cùng.
  - **NPC & xe:** điểm đi bộ sinh lại theo vỉa hè 14 stud → **267 điểm** (bỏ cả điểm rơi vào lòng đường tại giao lộ); vành đai giữa dời `±330 → ±338`. 3 tuyến xe kiểm bằng harness: **0 bước ra ngoài đường**.
  - Demo browser `/` và `/city` cập nhật đúng số liệu mới (1 m = 3,33 stud).
> **Agent phụ chuyên UI/UX + model súng:** prompt copy-paste đầy đủ ở
> [`agents/WORKER_PROMPT_V4_UI_WEAPONS.md`](agents/WORKER_PROMPT_V4_UI_WEAPONS.md) — 6 thẻ việc
> (`UI_W1_GUN_MODEL_FACTORY`, `UI_W2_HUD_RADAR`, `UI_W3_WEAPON_WHEEL_V2`, `UI_W4_INVENTORY`,
> `UI_W5_COMBAT_FX`, `UI_W6_PHONE`) đã có sẵn trong [`agents/AGENT_TASK_BOARD.json`](agents/AGENT_TASK_BOARD.json).

- [x] **Bước 13: DỌN DẸP + CHỈ RENDER THỨ TRONG MÀN HÌNH (`Sync v23`)** ✅
  - **Gỡ biệt thự "ít part" ở `Plot_E1`** theo yêu cầu Chủ dự án (kiểu dựng mới nhìn không đẹp bằng
    công trình chi tiết). `DestructibleShell.luau` vẫn giữ để dùng cho **tấm vỏ / panel kính**,
    nhưng **không dùng để dựng cả khối nhà** nữa. `Plot_E1` chờ Agent dựng lại **biệt thự chi tiết**.
  - **NPC không còn biến mất:** thêm `findGroundSoft()` (tia chiếu trượt thì rơi về đúng cao độ
    vỉa hè `Y = 1.15` thay vì bỏ qua), phương án dự phòng thả NPC quanh Legion Square nếu lưới
    vỉa hè sinh 0 điểm, **55 % NPC thả trong bán kính 320 stud quanh điểm hồi sinh** (luôn thấy phố
    đông), và **vòng nạp lại dân số mỗi 8 giây** (dưới 70 % mục tiêu thì thả bù). Có log chẩn đoán:
    `spawnAmbient: 84/84 NPC · 267 điểm vỉa hè · tia chiếu trượt N lần`.
  - **Chỉ render thứ có trong màn hình** — `src/client/CityCuller.luau`: cất công trình ở xa
    (> 900 stud) hoặc sau lưng camera (> 460 stud) ra khỏi `Workspace`, quay lại thì gắn về.
    Chi tiết nghiên cứu + thông số: [`docs/PERFORMANCE.md` §5.4](docs/PERFORMANCE.md).
  - **Bộ poll nghiệm thu tự động** — `bridge/agent-watch.mjs`: poll bản tin `agents/notes/`,
    nhánh `origin/arena/*`, rồi tự biên dịch module, đo quy mô (KB / vòng lặp / máu ẩn),
    chặn sửa file lõi và chặn commit `studio-sync.json`.
- [x] **Bước 14: NPC NHƯ NGƯỜI THẬT (`Sync v24`)** ✅
  - **★ TÌM RA ĐÚNG NGUYÊN NHÂN "THÀNH PHỐ TRỐNG, CHỈ CÓ 1 NPC MANG SKIN CỦA CHÍNH MÌNH".**
    Trong `NPCManager.spawn` có dòng:
    `local r15 = NPCAppearance.build(...)` rồi `model, hum, hrp, head = r15`.
    Hàm `build()` trả về **4 giá trị** nhưng gán vào **1 biến** thì chỉ giữ giá trị đầu (Model);
    đem Model đi băm theo chỉ số `1..4` → `hum/hrp/head = nil` → `hrp.Position` nổ ngay dòng kế tiếp
    → `pcall` trong `spawnAmbient` nuốt lỗi → **0/84 NPC được dựng**, im lặng hoàn toàn.
    Đúng một "NPC" người chơi nhìn thấy là **bản sao của chính họ** (`spawnPlayerTwin`), và đường
    này cũng dính y hệt lỗi (`local built = NPCAppearance.fromPlayer(...)`).
    → Sửa gọn: **nhận đủ 4 giá trị trả về** ở cả `NPCManager.spawn`, `NPCManager.spawnPlayerTwin`
    và `NPCAppearance.fromPlayer`. Từ đây mới kiểm chứng được mọi thứ khác.
  - **Harness chạy thật `NPCManager.luau` ngoài Studio** (`tools/npc_sim/`): mock `Instance/CFrame/
    Vector3/Humanoid/Raycast` + scheduler coroutine + **đồng hồ mô phỏng**. Kết quả **60 giây**:
    **93 NPC sống** (84 đi bộ + 1 bản sao + 8 tài xế) · **85/93 NPC đi > 8 stud** · **0 lỗi, 0 cảnh báo**.
  - **Hoạt động đời thường (section 9.6 trong `NPCManager.luau`):** tới đích thì **không đứng ngơ** mà
    bốc một hoạt động theo trọng số riêng của từng loại người —
    📞 **PHONE** (rút điện thoại thật khỏi túi, hàn vào `RightHand`, gật gù) · 💬 **TALK** (tìm NPC
    khác trong 18 stud, **cả hai quay mặt vào nhau**) · 👀 **LOOK** (dõi theo người chơi trong 34–40
    stud; không có ai thì ngó quanh phố) · 🛍️ **WINDOW** (đứng ngắm hàng, quay ra mặt đường) ·
    🧍 **IDLE**. Thời lượng 2–6 / 6–14 / 7–15 / 3–7 / 4–9 giây. Doanh nhân nghe điện thoại nhiều
    nhất, du khách ngắm cảnh nhiều nhất, đầu gấu/tay bo **không bao giờ** ngắm hàng.
  - **Người thật thì ai cũng một khác:** `BodyHeightScale 0,90–1,10` · `BodyWidthScale 0,92–1,08`
    · `BodyDepthScale` · `BodyTypeScale` · `HeadScale` ngẫu nhiên từng NPC. Thêm **jogger**
    (du khách 10 %, dân thường 8 %) chạy bộ `WalkSpeed ≥ 18` bằng animation `RUN`.
  - **Không bao giờ trống thành phố nữa:** `findGround` có **phương án hình học** (không phụ thuộc
    raycast: trong thành phố luôn trả `Y = 1.15`), mỗi NPC dựng trong `pcall` có đếm lỗi, **vòng cứu
    hộ 16 NPC** quanh Legion Square nếu vẫn ra 0, `init` **thử lại sau 6 s và 15 s** khi dân số < 20,
    và `NPCManager.diagnose()` in ra: số NPC sống · điểm vỉa hè · số jogger · **biểu đồ hoạt động**
    · tỉ lệ raycast trượt.
  - **Demo browser `/city`** mô phỏng đúng luật mới: mỗi NPC có chiều cao riêng, jogger chạy nhanh,
    vòng màu + emoji cho hoạt động đang làm, bảng đếm riêng 📞/💬/👀/🛍️/🧍.
  - **Tài liệu:** [`docs/NPC_BEHAVIOUR.md`](docs/NPC_BEHAVIOUR.md) (thiết kế + toàn bộ thông số) ·
    harness chạy lại bất cứ lúc nào: `node tools/npc_sim/run.cjs` → in `✅ PASS` khi thành phố có
    NPC sống, đi lại, làm việc và **0 cảnh báo**.
- [x] **Bước 15: MỖI NHÀ MỘT CHỨC NĂNG + CƠ CHẾ TAY + SÚNG VỀ VÒNG CHỌN (`Sync v25`)** ✅
  - **"MỖI NHÀ PHẢI CÓ CHỨC NĂNG"** — `src/shared/World/BuildingServices.luau` khai báo **15 quầy dịch vụ**
    cho 10 ô đất (ô C3 tách West/East), **12 loại chức năng**: `REPAIR_CAR` · `SPAWN_CAR` · `HEAL` ·
    `HEAL_FULL` · `ARMOR` · `AMMO` · `CLEAR_WANTED` · `UNLOCK_WEAPON` · `BANK_DEPOSIT` · `BANK_WITHDRAW`
    · `CINEMA` · `CAR_WASH`. `ServiceManager` dựng quầy thật (đế bê tông + pad neon + cột sáng 58 stud
    + biển hiệu BillboardGui) và **tự bật quầy ngay khi ô đất được nạp** — hết cảnh LS Customs có UI còn
    LSPD/Maze Bank bấm không ra gì.
  - **Quầy đặt theo CỬA THẬT, không dùng heuristic** (bản v25.0 từng đoán theo `center.Z` nên quầy
    nhảy ra giữa đường). Offset giờ suy trực tiếp từ attribute của module:
    C1 `PedestrianDoorPosition(−206,5 · Z 51)` → quầy `(−206,5 · 53,5)` · 24/7 `MainEntrance X=175 Z=92`
    → 3 quầy `(169 / 175 / 181 · 94,5)` · LSPD `MainGate 255 · 69,4` → 2 quầy `(251 / 259 · 72)` ·
    Maze Bank `MainEntrance X=0 Z=−65` (cổng rộng 16,4) → 2 quầy `(−11 / +11 · −61,5)`.
  - **Kiểm tra bằng mắt trước khi mở Studio:** trang `/services`
    ([`bridge/services-demo.html`](bridge/services-demo.html)) vẽ bản đồ 10 ô đất + 6 đại lộ, chấm phát
    sáng ở từng quầy (xanh = đang hoạt động, xám = chờ công trình), kệ đồ, danh sách quầy + giá.
    Dữ liệu lấy từ `/api/services` — server **đọc trực tiếp** `BuildingServices.luau` và
    `Carryables.luau` nên trang không bao giờ lệch với game.
  - **CƠ CHẾ TAY (vác đồ):** `src/shared/Carryables.luau` (5 loại: lốp · gạch · thùng · cọc · chai) +
    `src/server/CarryManager.luau` (7 kệ, 36 món quanh các quầy). Lại gần → `[E]` nhặt, món đồ được
    hàn vào **hai tay** bằng `Motor6D.Transform` (không phải tool), `[G]` thả, `[F]` hoặc chuột trái
    **ném** (gạch 78 stud/s, chai 86, lốp 52 — ném trúng tường trừ máu khối, trúng người trừ máu).
    HUD "ĐANG VÁC" hiện tên món + trọng lượng; chạy nhanh thì tay hạ thấp.
  - **SÚNG RA KHỎI HOTBAR, VÀO VÒNG CHỌN:** `WeaponManager` thêm `WeaponEquip` (client → server),
    `setEquipped`, `refillAmmo`, `grantWeapon`; `GtaWeaponWheel` phát `WeaponEquip` khi chọn ô, **khoá
    chọn súng khi đang vác đồ**; hotbar mặc định của Roblox bị tắt (`Backpack` CoreGui).
  - **`/api/services` cũng là hợp đồng QA:** `built[]` đọc `PlotId` trong `src/shared/World/Modules/*.luau`
    → quầy nào chưa có công trình thì hiện "CHỜ DỰNG" thay vì bịa ra quầy lơ lửng.
  - File: `BuildingServices.luau` (311 dòng) · `Carryables.luau` (129) · `ServiceManager.luau` (575) ·
    `CarryManager.luau` (439) · `CarryClient.luau` (200) · `bridge/services-demo.html` (10,6 KB).

- [x] **Bước 16 (đang chạy): QUÉT SẠCH THÀNH PHỐ — 3 Agent phụ × 2 vòng = 6 công trình chi tiết** ✅ 1/6
  - ✅ **`Plot_D1` — Luxury Autos** (agent `f3da0fbe`, nhánh `arena/f3da0fbe-…` @ `28349d7`) — **DUYỆT 9,1/10**.
    Đo lại độc lập bằng harness mới `tools/building_sim/`: **3 165 BasePart**, **99,59 % phá huỷ được**,
    0 khối nhỏ còn `CanCollide`, 0 `CanTouch`, 0 `CastShadow` sai, 0 `SurfaceGui` sai, 0 tên trùng,
    AABB nằm trọn trong ô đất. Mặt tiền **kính cong parabol 2 lớp** (446 ô kính `integrity 40`,
    `CanCollide = false` → xe tông xuyên), sảnh thông tầng 2 bục xoay + 3 xe, tầng lửng chữ U có
    văn phòng vách kính + quầy cà phê, sân trước 6 ô đỗ + barrier.
    Biên bản: [`agents/reviews/A1_ROCKFORD_LUXURY_AUTOS/MASTER_QA__b37b6115.md`](agents/reviews/A1_ROCKFORD_LUXURY_AUTOS/MASTER_QA__b37b6115.md).
  - ⏳ Còn 5 ô: D3 · E1 · E2 · E3 · E4.
- [x] **Bước 16.1: CÔNG CỤ ĐO CÔNG TRÌNH + GIẢI CHỖ ĐẶT QUẦY (`tools/building_sim/`)** ✅
  - `run.cjs <module.luau>` — dựng **module thật** trong Luau VM (mock Roblox API có **ma trận xoay
    3×3 thật**, `IsA` đúng cây kế thừa, `GetDescendants` đệ quy) rồi in: số BasePart · % khối phá huỷ ·
    AABB có xoay · khối nhỏ còn va chạm · `CanTouch` · `CastShadow` · `SurfaceGui` · tên trùng.
    → Từ nay **mọi bài agent phụ nộp đều bị đo lại**, không tin báo cáo tự khai.
  - `counter_check.cjs` — với từng quầy dịch vụ của ô đã dựng, kiểm tra **một cột trụ bán kính 4 stud**
    (đúng bán kính đế quầy 3,95) có bị tường/kính/cửa cuốn/cọc chắn/bậc chiếm không, và có **mặt đỡ
    thật** dưới chân không. `--solve` tự **giải** ra offset mới (lưới 0,5 stud) gần cửa nhất mà trống.
  - **Kết quả lần đầu chạy: 8/9 quầy nằm lọt trong tường** — đúng loại lỗi "đặt quầy bằng mắt".
    Sau khi giải và áp số: **9/9 quầy trống**, mặt đỡ đo được C1 1,28 · 24/7 1,30 · LSPD 1,34 ·
    Maze 1,27 · D1 1,37 (đều khác vỉa hè 1,15 → `ServiceManager.groundYAt()` raycast xuống lấy
    đúng mặt sàn thay vì cứng 1,15, nếu không đế quầy bị chôn hoặc lơ lửng).
- [ ] **Bước 17: PHÂN CÔNG VÒNG QUÉT V6** (prompt: [`agents/WORKER_PROMPT_V6_CITY_SWEEP_3AGENTS.md`](agents/WORKER_PROMPT_V6_CITY_SWEEP_3AGENTS.md))
  - Agent A: ~~`Plot_D1` Showroom Luxury Autos~~ ✅ → `Plot_E3` Quán nướng Seoul Garden
  - Agent B: `Plot_D3` Rạp Vinewood Cinema → `Plot_E4` TTTM Richman Galleria
  - Agent C: `Plot_E2` Garage La Mesa Customs → `Plot_E1` Biệt thự Pacific Bluffs (bản chi tiết)
  - Xong 6 công trình này là **10/10 ô đất có công trình** → thành phố hoàn chỉnh.
