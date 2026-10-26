# MASTER QA — A1_ROCKFORD_LUXURY_AUTOS (`Plot_D1`)

**Worker:** `f3da0fbe` · **Branch:** `arena/f3da0fbe-robloxstudio-connecting`
**Module duy nhất:** `src/shared/World/Modules/Plot_D1_RockfordShowroom.luau`
**Không sửa file lõi, không đụng `studio-sync.json`.**

---

## 1. Mô tả công trình

Showroom **Luxury Autos** 2 tầng + tầng lửng, dựng trực tiếp tại `Plot_D1`
(`X -318..-134`, `Z -204..-60`, nền `Y = 1.15`, không dùng `WorldGrid.RELOCATION`).

| Khu vực | Nội dung |
|---|---|
| Mặt tiền (+Z, ra Olympic Fwy) | Vách kính **cong parabol 2 lớp** (cách nhau 2.6 stud), khung thép trắng, 24 nhịp × 6 hàng × 2 lớp. Mỗi ô kính là 1 `BasePart` riêng với `integrity = 40`, `CanCollide = false` → **xe tông xuyên kính**. Có `CrashLane` (X -296..-272) không trụ dưới 14.5 stud. |
| Sảnh trệt | Sàn đá bóng caro 14×8, **2 bục xoay** đường kính 20 stud có đèn LED, **3 xe mô hình tĩnh** dựng bằng khối (đỏ / vàng / xanh), 12 bộ đèn rọi trần, quầy lễ tân, 4 tranh tường. |
| Tầng lửng (`Y = 16.20`) | Sàn chữ U ôm giếng trời, **cầu thang cong 18 bậc** + lan can kính, phòng **quản lý vách kính** (bàn/ghế/màn hình/tủ), **sofa da + bàn cà phê**, **quầy cà phê** + máy pha + 3 ghế đôn, 2 kệ **mô hình xe** (36 xe mini). |
| Tầng 2 (`Y = 28.00`) | Sàn vành khăn quanh giếng trời, lan can kính, 4 bệ trưng bày xe mini, 3 bảng thông tin, 6 chậu cây. |
| Mái (`Y = 39.2..40.0`) | Giếng trời kính 8 × 4 ô + khung nhôm, 3 cục HVAC, 2 cột ăng-ten, diềm mái + nắp inox. |
| Sân trước | 6 ô đỗ vạch vàng + gờ chặn bánh + số ô, vạch sang đường, barrier đỏ-trắng đang nâng 12°, **4 cột đèn sân**, 4 cây cọ, 6 bồn hoa, 2 ghế, 2 thùng rác, bó vỉa. |
| Biển hiệu | Chữ nổi **Neon trắng “LUXURY AUTOS”** (font 3×5, mỗi pixel 1 khối có máu) trên bảng 76 stud + `SurfaceGui`; pylon chữ “PREMIUM MOTORS · SIMEON YETARIAN”; biển cổng; biển giao nhận xe. |

## 2. Ảnh render (15 ảnh, 1200 × 750)

Rendering offline bằng trình vẽ PIL tự viết (painter's algorithm + clip mặt phẳng gần +
đổ bóng vật liệu) **từ chính JSON `BasePart` do Luau VM xuất ra** — không vẽ tay.

1. `01_hero_south.png`
2. `02_diag_southeast.png`
3. `03_diag_southwest.png`
4. `04_aerial_overhead.png`
5. `05_south_elevation.png`
6. `06_west_elevation.png`
7. `07_east_elevation.png`
8. `08_forecourt_parking.png`
9. `09_curved_glass_detail.png`
10. `10_interior_atrium.png`
11. `11_interior_turntables.png`
12. `12_mezzanine_office.png`
13. `13_night_facade.png`
14. `14_neon_sign_detail.png`
15. `15_second_floor.png`

Xem các file PNG cùng thư mục. Góc nhìn gồm: chính diện, 2 góc chéo, bird's-eye,
mặt đứng Đông/Tây, sân đỗ, cận cảnh kính cong, nội thất sảnh, 2 bục xoay,
văn phòng tầng lửng, tầng 2, cận biển Neon và **mặt tiền ban đêm**.

## 3. Phương pháp đo (số liệu thật, không ước lượng)

1. `qa_tools/run_luau.mjs` nạp **Luau VM thật** (`@luau-rs/luau` v0.739 / Luau v739),
   mock Roblox tối thiểu, **`PartBuilder.luau` thật** và module thật vào cùng 1 VM,
   gọi `Module.build(...)` rồi xuất từng `BasePart` (size, position, ma trận xoay,
   màu, vật liệu, transparency, cờ va chạm, HP ẩn, `SurfaceGui`) ra JSON.
2. `qa_tools/qa.py` quét JSON: AABB xoay thật, biên ô đất, trùng khối, **mặt đồng phẳng
   theo pháp tuyến + cắt đa giác Sutherland–Hodgman** (ngưỡng chồng > 1 stud²),
   đồ thị tiếp xúc chống lơ lửng (sai số 0.16 stud, BFS từ nền), cờ hiệu năng, GUI.
3. `node compile_all.mjs`: biên dịch **30/30 file Luau** trong repo — 0 lỗi parse.
4. `qa_tools/render.py` sinh 15 ảnh PNG từ cùng JSON đó.

Kết quả chạy lại: `OK: 3165 BaseParts exported`, `compiled 30/30 Luau files`.

---

## 4. BẢNG QA — đo trực tiếp

| Hạng mục | Kết quả | Gate |
|---|---:|---|
| Tổng `BasePart` | **3165** | 2 000–3 200 ✅ |
| Khối có máu ẩn (`Destructible=true`, `PartHealth>0`) | **3152 / 3165 = 99.59 %** | ≥ 95 % ✅ |
| `CanTouch = true` | **0** | 0 ✅ |
| `CanQuery = false` | **0** | 0 ✅ |
| Khối nhỏ (< 1.6 stud) còn `CanCollide` | **0** | 0 ✅ |
| Kính/Neon còn `CastShadow` | **0** | 0 ✅ |
| `SurfaceGui` sai `MaxDistance`/`TextScaled`/`PixelsPerStud` | **0** | 0 ✅ |
| Ô kính mặt tiền (`Transparency>0`) | **446** ( integrity ≤ 45: **446** ) | xe tông xuyên ✅ |
| AABB tổng | X **-316.00 .. -136.00** · Y **1.15 .. 46.80** · Z **-191.45 .. -61.10** | |
| Khối tràn biên `X -318..-134` / `Z -204..-60` / dưới nền `Y 1.15` | **0** | 0 ✅ |
| Cặp khối trùng hình học (vị trí + size + rotation) | **0** | 0 ✅ |
| Tên part trùng nhau | **0** | 0 ✅ |
| Cặp mặt phẳng đồng phẳng lộ thiên (diện tích chồng > 1 stud²) | **0** | 0 ✅ |
| Cặp mặt đồng phẳng cùng màu (bị che, không thấy) | 0 | thông tin |
| Khối lơ lửng (đồ thị tiếp xúc, sai số 0.16 stud) | **0** | 0 ✅ |
| Cửa đi bộ đôi (`MainDoorLeaf*`, 2 cánh) | **15.85 × 8.50 stud** (rộng × cao) | ≥ 8 cao ✅ |
| Cửa cuốn xe (`GarageRollupSlat*`, 10 nan) | **18.00 × 12.00 stud** | ≥ 15 × 11 ✅ |
| Mặt tiền kính (`FacadeGlass_*`) | **139.41 × 25.66 stud** (rộng × cao) | cao ≥ 16 ✅ |

## SurfaceGui

- `StallNumberPlate_01` · face `Top` · text `1` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `StallNumberPlate_02` · face `Top` · text `2` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `StallNumberPlate_03` · face `Top` · text `3` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `StallNumberPlate_04` · face `Top` · text `4` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `StallNumberPlate_05` · face `Top` · text `5` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `StallNumberPlate_06` · face `Top` · text `6` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `GateSignBoard` · face `Back` · text `LUXURY AUTOS  ·  ROCKFORD HILLS` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `GarageSign` · face `Left` · text `GIAO NHẬN XE  ·  DELIVERY` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `SignBoard_LuxuryAutos` · face `Back` · text `LUXURY AUTOS  ·  ROCKFORD HILLS  ·  OLYMPIC FWY` · MaxDistance `340.0` · PixelsPerStud `12.0` · TextScaled `False`
- `Pylon_Board` · face `Back` · text `LUXURY AUTOS  ·  PREMIUM MOTORS  ·  SIMEON YETARIAN` · MaxDistance `340.0` · PixelsPerStud `12.0` · TextScaled `False`
- `OfficeSign` · face `Back` · text `QUẢN LÝ  ·  MANAGER` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `CafeSign` · face `Back` · text `CAFÉ  ·  LUXURY LOUNGE` · MaxDistance `340.0` · PixelsPerStud `24.0` · TextScaled `False`
- `F2InfoBoard_1` · face `Back` · text `PREMIUM MOTORS  ·  SINCE 1972` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `F2InfoBoard_2` · face `Back` · text `LUXURY AUTOS  ·  TẦNG 2` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `F2InfoBoard_3` · face `Back` · text `PREMIUM MOTORS  ·  SINCE 1972` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `ShowroomBanner_1` · face `Right` · text `LUXURY` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `ShowroomBanner_2` · face `Right` · text `AUTOS` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `ShowroomBanner_3` · face `Right` · text `LUXURY` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `ShowroomBanner_4` · face `Right` · text `AUTOS` · MaxDistance `340.0` · PixelsPerStud `20.0` · TextScaled `False`
- `Reception_Sign` · face `Back` · text `CHÀO MỪNG ĐẾN VỚI LUXURY AUTOS` · MaxDistance `340.0` · PixelsPerStud `18.0` · TextScaled `False`


---

## 5. Tỉ lệ 1:1 & thông số kiến trúc

| Hạng mục | Giá trị đo được | Yêu cầu |
|---|---:|---|
| `WorldGrid.STUDS_PER_METER` | **3.33** | 1 m = 3.33 stud ✅ |
| Chiều cao thông thuỷ tầng trệt (`MEZZ_TOP - FLOOR_TOP`) | **14.84 stud ≈ 4.46 m** | ≥ 14 stud ✅ |
| Chiều cao thông thuỷ tầng 2 (`ROOF_BOT - L2_TOP`) | **11.20 stud ≈ 3.36 m** | tầng ~11 stud ✅ |
| Mặt tiền kính (rộng × cao) | **139.41 × 25.66 stud** (≈ 41.9 × 7.7 m) | cao ≥ 16 stud ✅ |
| Cửa đi bộ đôi | **15.85 × 8.50 stud** (≈ 4.76 × 2.55 m) | cao ≥ 8 stud ✅ |
| Cửa cuốn xe | **18.00 × 12.00 stud** (≈ 5.4 × 3.6 m) | ≥ 15 × 11 stud ✅ |
| Diện tích ô đất sử dụng | **X -316..-136 / Z -191.45..-61.10** | nằm trọn `-318..-134` / `-204..-60` ✅ |
| Độ cao lớn nhất | **Y 46.80** (ăng-ten mái) | không giới hạn |

`MULLION_W = WorldGrid.meters(0.10)` = 0.333 stud, `TRANSOM_H = WorldGrid.meters(0.09)`
= 0.30 stud — khung thép được định nghĩa theo mét rồi quy sang stud.

## 6. Tuân thủ `docs/PERFORMANCE.md` & HP ẩn

- **3152 / 3165** = **99.59 %** khối có `Destructible = true` + `PartHealth > 0`
  (13 tấm móng/sàn/mái chịu lực giữ `CanCollide = true` và không phá huỷ).
- Mọi part: `CanTouch = false`, `EnableFluidForces = false`, `CanQuery = true`.
- Khối < 1.6 stud: `CanCollide = false` (**0 vi phạm**).
- Kính / Neon / khối trong suốt: `CastShadow = false` (**0 vi phạm**).
- **446 ô kính** trong suốt, **446/446** có `integrity ≤ 45` ( = 40) → xe tông xuyên.
- `SurfaceGui`: `MaxDistance = 340`, `PixelsPerStud ≤ 32`, **không `TextScaled`**
  (dùng `TextSize` cố định), canvas lớn nhất 76 × 12 = 912 px ≤ 1 100 px.
- `perfPass()` chạy cuối `build()` duyệt `GetDescendants()` và áp toàn bộ cờ trên,
  kể cả các `SurfaceGui`/`TextLabel`.

## 7. Kết luận

**QA 0 lỗi:** 0 tràn biên · 0 khối trùng · 0 tên trùng · 0 mặt đồng phẳng lộ thiên ·
0 mặt đồng phẳng cùng màu · 0 khối lơ lửng · 0 cờ hiệu năng sai · 0 lỗi parse Luau.

Sẵn sàng nộp Agent Chính. PR mở vào `main`, **không tự merge**.

