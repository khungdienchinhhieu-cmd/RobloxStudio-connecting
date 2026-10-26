# 📤 NỘP VIỆC — `AGENT_7_STREET_INFRASTRUCTURE` (Đèn đường · Đèn tín hiệu · Cọ · Đồ đạc vỉa hè)

Agent 2 · nhánh `arena/7137180e-robloxstudio-connecting` · ngày 26/10/2026

---

## 1. Tên công trình / file, nhánh và SHA commit

| Mục | Giá trị |
|---|---|
| Task | `AGENT_7_STREET_INFRASTRUCTURE` (Order 80, ô `StreetProps`) |
| File duy nhất | `src/shared/World/Modules/Infra_StreetLightsAndPalms.luau` (912 dòng) |
| Nhánh | `arena/7137180e-robloxstudio-connecting` |
| SHA commit module | xem commit gần nhất chạm file trên nhánh (tin nhắn nộp bài trên bộ đàm ghi SHA) |
| File lõi bị sửa | **0** — không đụng `WorldGrid`, `PartBuilder`, `CityFoundation`, `DistrictRegistry`, `studio-sync.json` |
| Giao diện module | `Id = "Infra_StreetLightsAndPalms"`, `PlotId = "StreetProps"`, `Order = 80`, `Enabled = true`, `build()` trả `Folder` |

## 2. Số BasePart, AABB, số cặp đè, số tên trùng

| Hạng mục | Kết quả | Công cụ |
|---|---|---|
| BasePart | **2 283** | `node tools/building_sim/run.cjs src/shared/World/Modules/Infra_StreetLightsAndPalms.luau` |
| Khối có máu ẩn | **2 283 / 2 283 = 100,0 %** | nt |
| AABB | X −324,55 … +324,55 · Y **1,15 … 29,62** · Z −224,00 … +179,45 | nt |
| Nằm trong khung `StreetProps` (X ±340, Z −240…220) | **100 %** | nt |
| Khối lơ lửng (đáy < 1,15) | **0** | nt |
| **Cặp đè trong chính module** | **0** cặp > 6 stud³ | `node tools/building_sim/overlap_check.cjs Infra_StreetLightsAndPalms` |
| **Cặp đè với toàn thành phố** (nền `CityFoundation` + **11/11 module** đã dựng, 30 137 part) | **0** cặp > 6 stud³ | harness riêng (mục 2b) |
| **Khối chân/đế nằm trong lòng đường nhựa** | **0** (194 → 0 sau khi sửa, xem mục 5) | harness riêng (mục 2b) |
| Tên part trùng | **0 / 2 283** (mỗi part có hậu tố số thứ tự duy nhất) | `run.cjs` |
| Khối nhỏ < 1,6 còn `CanCollide` | 0 · `CanTouch = true`: 0 · `CastShadow` sai (kính/Neon): 0 · `SurfaceGui` sai: 0 · khối size 0: 0 | `run.cjs` |
| Biên dịch Luau (toàn repo) | **44/44 đạt** (chỉ biên dịch, không chạy) | `lua.load()` của `@luau-rs/luau` 0.739.0 |

**Số lượng hạng mục (attribute trên Folder gốc, đọc lại bằng máy):**

| Hạng mục | Số | Attribute |
|---|---:|---|
| Cột đèn cao áp LED | 56 | `LampCount` |
| Cột đèn tín hiệu | 10 | `TrafficSignalCount` |
| Cây cọ California | 30 | `PalmCount` |
| Ghế đá | 9 | `BenchCount` |
| Thùng rác | 13 | `BinCount` |
| Trụ nước chữa cháy | 24 | `HydrantCount` |
| Chậu cây | 9 | `PlanterCount` |
| Trạm xe buýt | 6 | `BusStopCount` |
| **Tổng vị trí** | **157** | — |

### 2b. Vì sao AABB không phải "mép vỉa hè 14 stud" như mô tả chung

Vỉa hè rộng 14 stud nhưng **công trình đã nghiệm thu lấn sát biên ô**: AABB thật của Plot_D1
chạm X = −316 (biên ô −318), Plot_C3_East chạm X = +312 (biên +318). Đặt cột "cách mép ô 2 stud"
là đè thẳng vào tường/ô đỗ xe của Agent khác. Nên toàn bộ 157 vị trí được **giải bằng máy**:

1. Dựng `CityFoundation` + **11/11 module** công trình trong Luau VM, áp đúng phép dời
   `WorldGrid.relocateTransform` như `DistrictRegistry` → **30 137 AABB** thật.
2. Bỏ part mỏng ≤ 5 cm (khe co giãn, sơn vạch — không chặn cột).
3. Dò ô trống 1 × 1 stud quanh từng vị trí, thử lùi ngang ±3 stud và xê dọc ±6 stud.
4. Loại trừ **vùng các Agent khác đã xin chừa trên bộ đàm**: bến bốc dỡ 24/7 (X 132–150,
   Z 24–52), bãi đỗ Nam siêu thị (X 132–216, Z 88–128), cổng soát vé LS Customs
   (X −274…−202, Z 115–128), mặt tiền LS Customs (X −219…−172, Z 46–64), cổng bộ hành
   Maze Bank (X ±14, Z −70…−59), 2 cửa cuốn xe Maze Bank (X ±78…96, Z −162…−136).
5. Loại trừ **lòng đường theo bảng `WorldGrid.EW_ROADS/NS_ROADS`** với bán kính chắn thật
   của từng hạng mục (xem mục 5 — đây là lỗi tôi tự tìm ra và đã sửa).
6. Loại trừ chéo: không để cột/cọ/ghế mọc xuyên mái trạm xe buýt (8 vị trí bị loại).

**Hai tuyến CỐ Ý không đặt** vì đã bị công trình chiếm kín: Vespucci phía Bắc nửa Plot_C2
(quảng trường Legion Square) và Olympic phía Bắc Plot_D1 (bãi đỗ 6 ô của Luxury Autos).

## 3. Chức năng thật đã làm

1. **Phá huỷ vật lý (máu ẩn):** mọi part truyền `integrity` → `Destructible = true`,
   `PartHealth = MaxPartHealth`. `StructuralRow` xếp tầng (1 = móng/bệ · 2 = thân cột/thân cọ
   · 3 = đầu đèn/tán lá) nên `DestructionManager` làm sập part trên khi part dưới vỡ:
   siêu xe tông gãy cột đèn thì đầu đèn rơi theo; bắn vỡ bầu cọ thì cả tán lá rụng.
   Máu: móng 320–340 · cột 260–300 · tán lá 40–90 · kính trạm 45 · thùng rác 90–130.
2. **Chiếu sáng ban đêm:** bóng đèn LED + 3 bóng tín hiệu + đèn đi bộ + bảng quảng cáo trạm
   đều là **Neon phát sáng** — thấy rõ ban đêm, **0 PointLight** (xem mục 5).
3. **Đèn tín hiệu có chu kỳ thật:** mỗi cụm mang attribute `SignalCycleSeconds = 40`,
   `GreenFrom = 0`, `GreenTo = 17`, `Intersection = "<tên ngã tư>"` để HUD/script server đọc.
   Chu kỳ ghi trong attribute: làn Bắc–Nam xanh 0–17 s, vàng 17–20 s; làn Đông–Tây xanh
   20–37 s, vàng 37–40 s. **Module không tự đổi màu** (ModuleScript không chạy được script
   phía server) — báo thật để anh quyết có cần script riêng hay không.
4. **Trạm xe buýt có mái che + ghế chờ + bảng quảng cáo Neon + biển hiệu** (6 trạm), ghế đá,
   thùng rác, trụ nước chữa cháy, chậu cây — đồ đạc đô thị đúng GTA V.
5. **Không chặn giao thông:** 0 khối chân/đế trong lòng đường; cần đèn và đầu đèn vươn trên
   cao (đáy ≥ 12 stud) nên xe GTA V cao 7 stud chạy qua dưới bình thường.

## 4. Ảnh QA

Trong `agents/reviews/INFRA_STREET_LIGHTS_AND_PALMS/` (vẽ từ AABB/OBB thật của module):

| Ảnh | Nội dung |
|---|---|
| `01_city_plan.png` | Mặt bằng toàn thành phố: 3 đại lộ Đông–Tây + 6 đại lộ Bắc–Nam + 10 ô đất + 153 dấu vị trí. Chú giải đếm khớp 100 % với attribute của module. |
| `02_asset_closeups.png` | Phối cảnh isometric 4 hạng mục tiêu biểu: cột đèn cao áp, đèn tín hiệu (cần 27 stud + 3 bóng + tủ điều khiển), cọ California (6 đốt + 8 tàu lá + 3 buồng dừa), trạm xe buýt. |
| `03_intersection_scene.png` | Toàn cảnh ngã tư Vespucci Blvd × Alta St (bán kính 210 stud): 2 cột tín hiệu ở 2 góc đối nhau, đèn đường nhịp 62 stud, cọ nhịp 30 stud, trạm xe buýt. |

Tôi đã mở và kiểm bằng mắt cả 3 ảnh; 2 lỗi hình học phát hiện qua ảnh đã sửa (mục 5).

## 5. Việc còn dở / rủi ro — nói thật

1. **ĐÃ SỬA — 194 khối chân đứng trong lòng đường.** Lần giải đầu tôi tính lùi theo khổ đường
   40 stud, nhưng San Andreas Ave và Alta St rộng **48** stud → cột đèn nằm trong làn xe.
   Nay mọi vị trí bị chặn theo bảng đường thật + bán kính hạng mục; kiểm lại **0 khối chân
   trong lòng đường**. `overlap_check.cjs` KHÔNG bắt được lỗi này (nó chỉ so part với part
   trong cùng module) — tôi phải tự viết phép kiểm lòng đường.
2. **ĐÃ SỬA — 2 đầu đèn tín hiệu chụm vào tim ngã tư.** Mỗi cột vươn cần theo cả 2 trục nên
   2 đầu đèn gần trùng nhau. Nay mỗi cột chỉ vươn **1 trục** (cột góc Tây–Nam vươn theo X,
   cột góc Đông–Bắc vươn theo Z), 2 đầu đèn phủ 2 hướng đường khác nhau.
3. **ĐÃ SỬA — tàu lá cọ xếp thành tầng ngang.** Tôi dịch tàu lá theo trục sai nên 8 tàu chồng
   lên nhau thành đĩa phẳng. Nay lá toả tròn 8 hướng, rủ xuống 2 đốt, AABB đỉnh 29,62 stud.
4. **26 vị trí đã đo nhưng đang TẮT.** Các tuyến Pacific Coast Hwy (X = −556), La Mesa Ave
   (X = +556) và dải đi bộ Vinewood Bắc (Z = −250) **nằm ngoài khung `StreetProps` khai trong
   `AGENT_TASK_BOARD.json`** (X ±340, Z −240…220) nhưng **nằm trong bản đồ thật**
   (`MAP_HALF_SIZE = 580`). Tôi để cờ `INCLUDE_OUTER_AVENUES = false` ở đầu file để không bị
   báo "tràn biên". Đổi thành `true` là 26 vị trí bật lên. **Anh quyết giúp:** khung trong
   board đã cũ, nên cập nhật board hay giữ nguyên?
5. **Không có PointLight.** `docs/PERFORMANCE.md` §6 nói mỗi PointLight bật bóng rất tốn;
   56 cột đèn × 1 PointLight là 56 nguồn sáng động toàn bản đồ. Tôi để công tắc
   `ENABLE_LAMP_POINT_LIGHTS = false`. Hệ quả: ban đêm vỉa hè sáng bằng Neon nhưng **không
   hắt sáng xuống mặt đường**. Nếu anh muốn hắt sáng thật, nên bật cho ~10 cột gần Legion
   Square thay vì cả 56.
6. **RỦI RO CHO VIỆC #2 (CityCuller) — tôi phát hiện khi đọc code, chưa sửa:**
   `CityCuller` coi **mỗi child của `DistrictModules` là 1 khối cull** và lấy **1 pivot**.
   Module của tôi là 1 `Folder` phủ toàn bản đồ (1 160 × 480 stud) → `GetPivot()` của Folder
   rơi về gốc toạ độ (0, 0, 0). Hệ quả: đứng ở rìa phía Đông (X ≈ +556) quay mặt ra ngoài,
   gốc O nằm **sau lưng** ở khoảng cách 556 > `BEHIND_RADIUS = 460` ⇒ **toàn bộ đèn đường,
   cọ, ghế, trạm xe buýt của cả thành phố bị cất cùng lúc**. Đây đúng là **cùng một lớp lỗi
   với "nhà biến mất khi đi gần"** mà anh giao tôi ở việc #2. Đề nghị: khi làm CityCuller, chia
   khối cull theo **ô lưới 120 stud** thay vì theo child của `DistrictModules`.
7. **Chưa kiểm trong Roblox Studio thật.** Toàn bộ số liệu trên là harness Luau VM (mock
   Roblox API) + render Python. Chưa chạy `StreamingEnabled` + `DistortionManager` thật, nên
   chưa xác nhận được hiệu năng thật và cảm giác phá huỷ trong game.
8. **Server chưa có script đổi pha đèn.** Như mục 3.3 đã nói: attribute có sẵn, nhưng cần
   thêm script (file mới, không phải file lõi) mới thấy đèn chuyển màu. Việc này **ngoài phạm
   vi 1 file** của tôi nên tôi không tự làm.
