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

## 🗺️ Quy Hoạch Bản Đồ Đối Xứng (`WorldGrid.luau` — `720 × 720 studs`)

| Mã Khu | Tên Khu Vực (Los Santos) | Tọa độ X (`studs`) | Tọa độ Z (`studs`) | Trạng thái |
| :--- | :--- | :---: | :---: | :--- |
| **North Ridge** | **Vinewood Hills** (Đồi vát nghiêng tự nhiên, vách đá & tường chắn ghép khối) | `[-360, +360]` | `[-360, -240]` | ✅ Hoàn thành ở Nền v2 |
| **Plot D1** | **Rockford Hills** (Ô móng kỹ thuật sạch chờ công trình) | `[-308, -128]` | `[-208, -54]` | ⏳ Chờ dựng từng công trình |
| **Plot D2** | **Pillbox Hill** (Ô móng kỹ thuật sạch chờ Tháp Maze Bank) | `[-92, +92]` | `[-208, -54]` | ⏳ Chờ dựng từng công trình |
| **Plot D3** | **Downtown Vinewood** (Ô móng kỹ thuật sạch chờ công trình) | `[+128, +308]` | `[-208, -54]` | ⏳ Chờ dựng từng công trình |
| **Plot C1** | **Del Perro — Los Santos Customs** (`3,462` parts, `98.1%` máu ẩn, 2 khoang độ xe **có chức năng thật** `[E]`) | `[-308, -128]` | `[-18, +132]` | ✅ Nghiệm thu v10 — đã lên Studio (`Sync v9`) |
| **Plot C2** | **Legion Square** (Nền quảng trường bậc cấp, hồ nước & tường gạch ghép khối) | `[-92, +92]` | `[-18, +132]` | ✅ Hoàn thành ở Nền v2 |
| **Plot C3** | **Mission Row** (Nửa Tây: Siêu thị 24/7 `934` parts • Nửa Đông: **Đồn LSPD Mission Row `4 639` parts, `99.6%` máu ẩn**) | `[+128, +308]` | `[-18, +132]` | ✅ **Cả 2 nửa nghiệm thu** — `Sync v13` |
| **South Coast** | **Vespucci Beach** (Kè đá ghép khối, cầu thang xuống biển, sàn gỗ, kè chắn sóng) | `[-360, +360]` | `[+164, +360]` | ✅ Hoàn thành ở Nền v2 |

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
- [ ] **Bước 7: Công trình #4 — Tháp Tài Chính Maze Bank Tower (`Plot D2`)**
