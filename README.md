# 🌴 Dự Án GTA V Roblox — Los Santos Modular (Destructible Edition)

Dự án tái hiện thế giới mở **Grand Theft Auto V (Los Santos)** trên Roblox Studio theo kiến trúc **ghép từng phần siêu chi tiết** và **kết cấu khối vật lý có thể phá huỷ (`Modular Destructible Voxels`)**.

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

- [x] **Bước 1 (Đang hoàn thiện v2): GTA V HUD (Phím `[H]` mở Menu Test) + Đại Tu Toàn Bộ Nền Thành Phố Ghép Khối**
  - **UI (`GtaHud.luau`):** Màn hình mặc định sạch chuẩn GTA V 100%; nhấn phím **`[H]`** để đóng/mở bảng **Los Santos Dev Menu** (thử Sao truy nã, Tiền, Giáp, Máu).
  - **Nền Thành Phố Siêu Chi Tiết (`CityFoundation.luau` + `VoxelBuilder.luau`):**
    - Hệ thống đường nhựa có rãnh thoát nước bê tông (`Gutter`), song chắn rác kim loại âm vỉa hè, dốc hạ vỉa hè cho người đi bộ tại 48 góc ngã tư, đinh phản quang phân làn (`Botts' Dots`), mũi tên chỉ hướng & vạch `STOP`.
    - Đại lộ trung tâm `Olympic Fwy` có **dải phân cách bê tông K-Rail (Jersey Barriers) ghép từ từng khối rời `Destructible = true`**.
    - Bờ biển **Vespucci Beach** có bờ kè đá xây từng viên gạch so le (`Destructible = true`), 3 cụm cầu thang đá đi bộ xuống bãi cát, đường dạo lát ván gỗ, mỏm đá chắn sóng vươn ra biển và 4 tầng màu nước biển chuyển sắc.
    - Dãy đồi **Vinewood Hills** tạo hình sườn dốc tự nhiên bằng khối vát đa diện (`WedgePart`), vách đá sa thạch, đường mòn sườn đồi và tường kè đá ghép khối chống sạt lở.
    - Nền quảng trường **Legion Square** lát gạch đa sắc, bồn cây xây từ từng viên đá rời, cọc tiêu bảo vệ vỉa hè (`Destructible = true`) và 5 ô móng công trình kỹ thuật phẳng phiu có lối xe chạy vào (`Driveway Apron`).
- [ ] **Bước 2: Hạ tầng Đường phố (Đèn giao thông ngã tư, Đèn đường đôi & Hàng cọ California — ghép đoạn có thể húc đổ)**
- [ ] **Bước 3: Công trình #1 — Garage Độ Xe Los Santos Customs (`Plot C1` — làm duy nhất 1 công trình cực chỉnh chu, tường gạch/cửa cuốn ghép khối phá huỷ)**
- [ ] **Bước 4: Hệ thống Xe Hơi GTA V & Cơ chế Va chạm / Phá huỷ Khối Vật Lý (`DestructionEngine`)**
- [ ] **Bước 5: Công trình #2 — Cửa hàng Tiện lợi 24/7 Supermarket (`Plot C3` — full nội thất kệ hàng & kính vỡ từng mảnh)**
- [ ] **Bước 6: Công trình #3 — Đồn Cảnh Sát Mission Row LSPD (`Plot C3`)**
- [ ] **Bước 7: Công trình #4 — Tháp Tài Chính Maze Bank Tower (`Plot D2`)**
