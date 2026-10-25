# 🌴 Dự Án GTA V Roblox — Los Santos Modular

Dự án tái hiện thế giới mở phong cách **Grand Theft Auto V (Los Santos)** trên Roblox Studio theo phương pháp **chia nhỏ từng phân khu độc lập (Modular Architecture)**, kiểm thử trực quan trên **Trình duyệt (Browser Simulator)** trước khi ghép nối trực tiếp vào **Roblox Studio** qua **GitHub Live Bridge (CDN)**.

---

## 🧭 Quy Trình Làm Việc Chuẩn (Áp dụng cho mọi Giai đoạn)

1. **Thiết kế Module độc lập:** Mỗi hạng mục (UI, Nền đường, từng Khu phố, Xe cộ, Cửa hàng, LSPD...) nằm trong một `ModuleScript` riêng biệt trong `src/`, bám sát hệ trục tọa độ chuẩn `WorldGrid.luau`.
2. **Kiểm thử trên Browser của Agent trước:** Chạy bộ mô phỏng 3D + UI từ chính mã Luau để xuất ảnh chụp thực tế, kiểm tra bố cục, màu sắc, tỷ lệ, độ tương phản và sửa cho thật chuẩn đẹp.
3. **Đồng bộ sang Roblox Studio:** Sau khi đạt chuẩn thẩm mỹ trên Browser, đóng gói vào `studio-sync.json` và đẩy qua CDN để cập nhật tức thì vào `Workspace.LosSantos`.

---

## 🗺️ Quy Hoạch Bản Đồ Tổng Thể (`WorldGrid.luau` — `720 × 720 studs`)

| Mã Ô Đất | Tên Khu Vực (Cảm hứng GTA V) | Tọa độ X (`studs`) | Tọa độ Z (`studs`) | Trạng thái |
| :--- | :--- | :---: | :---: | :---: |
| **North Ridge** | **Vinewood Hills** (Đồi xanh phân tầng phía Bắc) | `[-360, +360]` | `[-360, -240]` | ✅ Đã tạo nền đồi (GĐ 1) |
| **Plot D1** | **Rockford Hills** (Khu Biệt Thự & Luxury Boutique) | `[-308, -128]` | `[-208, -54]` | ⏳ Ô đất sạch chờ GĐ 3 |
| **Plot D2** | **Pillbox Hill** (Tháp Tài Chính Maze Bank Downtown) | `[-92, +92]` | `[-208, -54]` | ⏳ Ô đất sạch chờ GĐ 3 |
| **Plot D3** | **Downtown Vinewood** (Đại lộ Điện Ảnh & Studio) | `[+128, +308]` | `[-208, -54]` | ⏳ Ô đất sạch chờ GĐ 3 |
| **Plot C1** | **Del Perro** (Los Santos Customs & Cửa Hàng Ven Biển) | `[-308, -128]` | `[-18, +132]` | ⏳ Ô đất sạch chờ GĐ 3-4 |
| **Plot C2** | **Legion Square** (Quảng Trường Trung Tâm, Hồ Nước & Điểm Spawn) | `[-92, +92]` | `[-18, +132]` | ✅ Đã hoàn thiện (GĐ 1) |
| **Plot C3** | **Mission Row** (Sở Cảnh Sát LSPD & Khu Thương Mại) | `[+128, +308]` | `[-18, +132]` | ⏳ Ô đất sạch chờ GĐ 3-5 |
| **South Coast** | **Vespucci Beach & Pacific Ocean** (Phố đi bộ, Cát vàng & Biển) | `[-360, +360]` | `[+164, +360]` | ✅ Đã tạo bờ biển (GĐ 1) |

### Hệ thống 7 Đại lộ Đối xứng (Khít `0.000 stud`)
- **Trục Đông – Tây (`X = -340 .. +340`):**
  - `Vinewood Blvd` (`Z = -224`, rộng `32 studs`, 2 làn)
  - `Olympic Fwy` (`Z = -36`, rộng `36 studs`, đại lộ trung tâm 4 làn vạch đôi vàng)
  - `Vespucci Blvd` (`Z = +148`, rộng `32 studs`, đại lộ ven biển 2 làn)
- **Trục Bắc – Nam (`Z = -240 .. +164`, đối xứng qua `X = 0`):**
  - `Del Perro Fwy` (`X = -324`, rộng `32 studs`, 2 làn)
  - `San Andreas Ave` (`X = -110`, rộng `36 studs`, 4 làn)
  - `Alta St` (`X = +110`, rộng `36 studs`, 4 làn)
  - `Elgin Ave` (`X = +324`, rộng `32 studs`, 2 làn)

---

## 📋 Lộ Trình Từng Giai Đoạn Nhỏ (Checklist Tiến Độ)

- [x] **Giai đoạn 1 (Hiện tại): Giao diện GTA V (UI) & Nền Thành Phố Los Santos**
  - **GTA V HUD (`src/client/UI/GtaHud.luau`):**
    - Bản đồ nhỏ hình chữ nhật góc dưới trái (**Live Rectangular Minimap**) cuộn & xoay theo vị trí thực tế, hiển thị đường phố, bờ biển, hướng Bắc (`N`) và chớp Xanh-Đỏ khi bị truy nã.
    - Bộ 3 thanh chỉ số sát đáy Minimap chuẩn GTA V: **Máu (Xanh lá 50%)** • **Giáp (Xanh dương 25%)** • **Thể lực / Kỹ năng (Vàng 25%)**.
    - Góc trên phải: **5 Sao Truy Nã (`★`)** chớp sáng + **Tiền Mặt (`$`)** kèm hiệu ứng cộng/trừ tiền + Giờ trong game.
    - Góc dưới phải: Chữ nghệ thuật báo **Tên Đường & Khu Phố** tự động hiện khi di chuyển sang đường mới.
    - Hộp thông báo đen mờ phía trên Minimap + Phím **`[H]`** bật/tắt nhanh thanh Test thử Sao truy nã, Tiền, Giáp, Máu.
  - **Nền Thành Phố (`src/shared/World/CityFoundation.luau`):**
    - Mạng lưới đại lộ nhựa Asphalt đen mịn, vạch đôi vàng California, vạch phân làn trắng đứt nét, vạch dừng ngã tư & vạch qua đường.
    - Vỉa hè bê tông giật cấp có bó vỉa xám/đỏ, cống thoát nước mưa, nắp hố ga kim loại và các **ô nền dự án (`Plot Pads`)** đánh dấu sẵn cho các giai đoạn sau.
    - Bờ biển cát thoải **Vespucci Beach** nối ra mặt nước biển Thái Bình Dương xanh ngọc (phía Nam) và dải đồi **Vinewood Hills** phân tầng (phía Bắc).
- [ ] **Giai đoạn 2: Quảng trường Legion Square, Hàng cọ California & Đèn đường đôi Los Santos**
- [ ] **Giai đoạn 3: Hệ thống Siêu xe GTA V (Vật lý lái mượt, Đồng hồ tốc độ, Đài Radio) & Garage LS Customs**
- [ ] **Giai đoạn 4: Cụm Cao ốc Downtown (Tháp Maze Bank & Căn hộ Eclipse Towers có thang máy)**
- [ ] **Giai đoạn 5: Chuỗi Cửa hàng Tương tác (Siêu thị 24/7, Burger Shot, Cây ATM Maze Bank)**
- [ ] **Giai đoạn 6: Khu vui chơi Cầu cảng Del Perro Pier & Vòng quay Mặt Trời phát sáng**
- [ ] **Giai đoạn 7: Cư dân NPC, Xe cộ lưu thông & Hệ thống Cảnh sát LSPD theo Sao Truy Nã (1★–5★)**

---

## 🔗 Lệnh Kết Nối Trực Tiếp Vào Roblox Studio (Command Bar)
Mở **View → Command Bar** trong Roblox Studio và dán dòng lệnh hiển thị trên bảng **Live Preview** (hoặc trong tin nhắn mới nhất của Agent) để đồng bộ tự động qua GitHub CDN.
