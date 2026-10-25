# ✅ BIÊN BẢN NGHIỆM THU ĐẠT 100%: `AGENT_1_LS_CUSTOMS` (Los Santos Customs — `Plot_C1`)

- **Người nghiệm thu:** Agent Chính (`arena/b37b6115-robloxstudio-connecting`)
- **Nhánh tác giả:** `arena/e461e643-robloxstudio-connecting`
- **File tích hợp:** `src/shared/World/Modules/Plot_C1_LSCustoms.luau`
- **Kết quả đo kiểm tự động trong Luau VM:**
  - Tổng số khối (`BasePart`): **`3,462` parts**
  - Mật độ máu ẩn (`Destructible = true` & `PartHealth > 0`): **`3,396 / 3,462` (`98.1%`)**
  - Ranh giới thực tế: `X ∈ [-297.50 .. -138.50]`, `Z ∈ [-8.85 .. +122.90]` (Nằm gọn 100% trong `Plot_C1`, **`0` khối tràn biên**, **`0` tấm Z-fighting**)
  - Thông thuỷ 2 khoang cửa cuốn cho siêu xe (`8.2w × 7.57h`): **`0` vật cản**
- **Hiệu chỉnh tinh tế khi nghiệm thu của Agent Chính:**
  1. Nâng cấp `DistrictRegistry.luau` tự động dọn tường bao tạm (`PerimeterWall_*` / `SurveyMonument`) của ô trống `Plot_C1` để cổng Nam thông suốt ra đại lộ `Vespucci Blvd`.
  2. Dời băng ghế gỗ ngoài trời & cọc tiêu số 6 sang sát vách kính phòng chờ khách (`X = -197, -183`) để làn xe vào Khoang 2 thông thoáng tuyệt đối, đồng thời đẩy nổi chữ Neon `"LOS SANTOS CUSTOMS"` thêm `+0.20` stud cho sắc nét 100%.

---

## 🔧 VÒNG NGHIỆM THU 2 (v10) — Vá 3 phản hồi trực tiếp của Chủ dự án

Chủ dự án chấm **9/10** và nêu 3 điểm: *(1) khối bị chồng lên nhau, (2) chưa có chức năng gì cả, (3) trang trí hơi rối mắt.* Toàn bộ 3 điểm đã xử lý xong và đo lại tự động:

### 1. Khối chồng lên nhau — `0` cặp mặt phẳng trùng cao độ
| Lỗi gốc | Nguyên nhân | Cách vá |
| :--- | :--- | :--- |
| Mảng sàn tối loang lổ trên sân trước | `WestYardSlab` / `EastYardSlab` size `26 × 0.22 × 129` tại `Z = 57` trùm lên **35 ô** `ForecourtSlab_*` (mặt trên lệch đúng `0.03` -> Z-fighting) | Cắt còn `26 × 0.22 × 58.7` tại `Z = 21.85` (chỉ lát sân hông phía Bắc, gặp sân trước là dừng) |
| Kệ sắt bị thùng gỗ xuyên qua | `EastPalletRack` là **1 khối đặc** `2 × 8 × 9` chứa 3 thùng gỗ bên trong | Đổi thành **giá kệ HỞ**: 4 chân đứng `0.26² × 8.4` + 6 dầm dọc + 6 dầm ngang ở 3 cao độ, thùng gỗ nằm **trên** dầm |
| Vết dầu chồng sàn epoxy | `OilStain` mặt trên `1.345` vs `EpoxyBayFloor` `1.34` (lệch `0.005`) | Nâng vết dầu lên `Y = FLOOR_TOP + 0.055` (lệch `0.03`) |
| Mặt bàn quầy lễ tân | `CounterTop` và `CounterTopReturn` cùng mặt trên `5.825` | Hạ `CounterTopReturn` xuống `0.03` |

### 2. Trang trí rối mắt — giảm từ `189` → `~60` vật thể ở sân trước
- Jitter bê tông `10 → 2`: sàn sân trước **đồng màu** thay vì 7 sắc xám loang lổ.
- Bỏ dòng chữ `"CUSTOMS"` sơn phẳng chồng lên logo `"LSC"`.
- Cọc tiêu: `6 → 3`, xếp **thẳng hàng trước 3 trụ nhà** (`X = -266 / -243.5 / -218`, `Z = 108`) — không còn cọc nằm giữa làn xe.
- Băng ghế: `2 → 1` (giữa mái hiên kính); Chậu cây: `3 → 2` (đối xứng 2 bên cửa đi bộ); Thùng rác: `2 → 1`.
- Chồng lốp `2 → 1`, phuy dầu `3 → 2`, bỏ `PalletBase` + 3 thùng gỗ ngoài sân.
- Vạch ô đỗ `4 → 3`/bên, gờ chặn bánh `3 → 2`/bên, bỏ 6 mảng nhựa tối `StallNumber`.
- Thêm **2 mũi tên vàng** (thân + 2 cánh chéo `42°`) dẫn làn vào 2 khoang.

### 3. Chức năng thật — 2 khoang độ xe hoạt động 100%
- **World** (`Plot_C1_LSCustoms.luau`): `BayZone1/2` (`19.3 × 13 × 46`, vô hình, `BayIndex` + `LSCustomsTrigger`), `BayStatusStrip1/2` (LED mặt sàn), `BayStatusLamp1/2` (đèn cầu) + `BayLampHousing`, bảng `MOD SHOP` trên vách kính.
- **Server** (`src/server/LSCustomsService.luau`): quét `0.35s/lần`; **SỬA CHỮA `$250`**, **SƠN LẠI `$500`** (8 màu GTA V), **TURBO `$1.500`** (`+8 MaxSpeed`/cấp × 3 cấp); chặn thiếu tiền / Turbo tối đa / khoang trống / spam `0.5s`.
- **Client** (`src/client/UI/LSCustomsUI.luau`): chip `[E]` sát đáy màn hình + bảng độ xe `[1] [2] [3]`, `[ESC]` đóng.
- **Test:** `17/17` PASS trên harness DOM (`/tmp/dom_test.mjs`) + bản demo tương tác `bridge/lscustoms-demo.html` phục vụ tại **`http://<preview>:8080/lscustoms`**.
