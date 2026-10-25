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
| **Plot C1** | **Del Perro** (Ô móng kỹ thuật sạch chờ LS Customs) | `[-308, -128]` | `[-18, +132]` | ⏳ Chờ dựng từng công trình |
| **Plot C2** | **Legion Square** (Nền quảng trường bậc cấp, hồ nước & tường gạch ghép khối) | `[-92, +92]` | `[-18, +132]` | ✅ Hoàn thành ở Nền v2 |
| **Plot C3** | **Mission Row** (Ô móng kỹ thuật sạch chờ Đồn LSPD) | `[+128, +308]` | `[-18, +132]` | ⏳ Chờ dựng từng công trình |
| **South Coast** | **Vespucci Beach** (Kè đá ghép khối, cầu thang xuống biển, sàn gỗ, kè chắn sóng) | `[-360, +360]` | `[+164, +360]` | ✅ Hoàn thành ở Nền v2 |

---

## 📋 Lộ Trình Triển Khai Từng Bước Nhỏ

- [x] **Bước 1: GTA V HUD (Phím `[H]` mở Menu Test) + Đại Tu Toàn Bộ Nền Thành Phố Ghép Khối (`2,803` parts)**
- [x] **Bước 2 (Hiện tại): Hệ thống Xe Hơi GTA V + Máu Ẩn Cho Từng Part (`PartHealth`) & Tự Vỡ Khi Xe Đụng / Bị Bắn**
  - **Máu Ẩn Từng Khối (`PartBuilder.luau` + `DestructionManager.luau`):** Mọi viên gạch, đốt dải phân cách K-Rail, cọc tiêu thép, bờ kè đá, tượng đài và **từng bộ phận vỏ xe** (cản trước/sau, nắp capo, kính chắn gió, 2 cửa xe, đèn pha/hậu, cánh gió) đều có máu ẩn `PartHealth`. Khi bị xe tông hoặc súng bắn sẽ sẫm màu/nứt dần và **tự động vỡ tung thành mảnh vật lý văng ra** ngay khi hết máu ẩn (kèm sập dây chuyền các viên gạch phía trên).
  - **Xe Hơi GTA V Cao Thoáng + Full Nội Thất Cockpit + Diễn Hoạt Mở Cửa `[F]` (`VehicleBuilder.luau` + `VehicleManager.luau`):** Dòng Coupe thể thao `Banshee GT` & Muscle `Gauntlet GTX` nâng cao trần ca-bin (`~5.68` studs), trang bị **28+ chi tiết nội thất** (vô lăng 3 chấu đáy phẳng + lẫy số, chân ga/phanh, đồng hồ phát sáng, màn hình GPS, 4 cửa gió điều hoà, bệ trung tâm + cần số + phanh tay + khay cốc, ghế đua 2 tông màu có gối tựa đầu thanh crôm, gương hậu trong + che nắng + đèn trần tự sáng khi mở cửa) và **khớp bản lề cửa thực (`LeftDoorHinge`/`RightDoorHinge`) mở xoay `64°` mượt mà khi bấm `[F]` lên/xuống xe**!
  - **Súng Kiểm Thử Phá Huỷ (`WeaponManager.luau` + `WeaponClient.luau`):** Trang bị sẵn `Pistol 9mm` & `Carbine Rifle` có tâm ngắm chấm trắng chuẩn GTA V, tia đạn và hiệu ứng bắn vỡ từng viên gạch / kính xe / cánh cửa xe.
- [ ] **Bước 3: Hạ tầng Đường phố (Đèn giao thông ngã tư, Đèn đường đôi & Hàng cọ California — có máu ẩn, xe tông gãy đổ)**
- [ ] **Bước 4: Công trình #1 — Garage Độ Xe Los Santos Customs (`Plot C1` — làm duy nhất 1 công trình cực chỉnh chu, tường gạch/cửa cuốn có máu ẩn phá huỷ)**
- [ ] **Bước 5: Công trình #2 — Cửa hàng Tiện lợi 24/7 Supermarket (`Plot C3` — full nội thất kệ hàng & kính vỡ từng mảnh)**
- [ ] **Bước 6: Công trình #3 — Đồn Cảnh Sát Mission Row LSPD (`Plot C3`)**
- [ ] **Bước 7: Công trình #4 — Tháp Tài Chính Maze Bank Tower (`Plot D2`)**
