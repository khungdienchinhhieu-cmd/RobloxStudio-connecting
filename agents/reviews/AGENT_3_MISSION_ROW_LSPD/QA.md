# AGENT_3_MISSION_ROW_LSPD — Đồn Cảnh Sát Mission Row (LSPD)

- Module: `src/shared/World/Modules/Plot_C3_MissionRowLSPD.luau`
- Plot: `Plot_C3_East` — Bounds X 222..299, Z -9..123, groundY = 1.15
- Branch: `arena/e461e643-robloxstudio-connecting`

## Số liệu QA (bắt buộc)

| Hạng mục | Kết quả | Gate |
|---|---|---|
| Luau compile | 0 lỗi | ✅ |
| Tổng BasePart | **4554** | — |
| Destructible (máu ẩn) | **4535 / 4554 = 99.6 %** | ≥ 90 % ✅ |
| AABB X | 223.50 .. 298.50 | trong 222..299 ✅ |
| AABB Y | 1.15 .. 49.05 | ground 1.15, không khối nào dưới nền ✅ |
| AABB Z | -2.09 .. 122.50 | trong -9..123 ✅ |
| Khối ra ngoài bounds | **0** | 0 ✅ |
| Part < 1.6 stud mà CanCollide = true | **0** | 0 ✅ |
| Sàn/mái mỏng rộng mà CanCollide = false | **0** | 0 ✅ |
| CanTouch = true | **0** | 0 ✅ |
| EnableFluidForces = true | **0** | 0 ✅ |
| CastShadow sai (nhỏ / kính / Neon) | **0 / 0 / 0** | 0 ✅ |
| Khối trùng lặp | **0** | 0 ✅ |
| Khối lơ lửng | **0** | 0 ✅ |
| Cặp mặt đồng phẳng **nhìn thấy được** (z-fighting) | **0** (diện tích 0.00) | 0 ✅ |
| Cặp mặt áp sát bị che (không z-fighting) | 52 (diện tích 44.7) | thông tin |
| SurfaceGui / TextScaled | không dùng — chữ nổi ghép khối 3D | ✅ |

Ghi chú: 52 cặp "coplanar" còn lại là các mặt áp lưng vào nhau (block kề block, coping ↔ tường
lan can, đáy cornice ↔ đỉnh cột). Một bộ lọc che khuất (occlusion test trên grid) xác nhận
**0 cặp nào lộ ra ngoài** → không có z-fighting.

## Kích thước kiến trúc

- Khối nhà X 232..282 (50) × Z 4..70 (66), tường ngoài 1.2, cao tới đỉnh lan can 34.50.
- Tầng trệt: sàn 2.09 → trần 17.00 (**thông thuỷ 14.91 ≥ 14**).
- Tầng 2: 17.39 → 32.00 (14.61).
- Cửa kính đôi chính: **8.0 rộng × 9.0 cao** (X 251..259, mặt Z = 70).
- Cửa cuốn Sally Port: **18 rộng × 12 cao** (mặt Đông X = 282, Z 20..38) ≥ 15 × 11.
- Bãi đỗ xe cảnh sát: 3 ô (vạch X 267.0 / 276.6 / 286.2 / 295.8, Z 85..114) + gờ chặn bánh Z 110.5..111.5.

## Toạ độ bàn giao (Agent 7 — không chặn)

| Vùng | Toạ độ |
|---|---|
| Cửa chính + tam cấp | mặt tiền Z = 70, cửa X 251..259; bậc Z 76.0..79.4; sân đá Z 69.2..76.0 |
| Bãi đỗ xe cảnh sát (3 ô) | X 266..296, Z 84..114 — **giữ trống** |
| Cổng bãi xe | trụ X 262.9..266.3 & 294.9..298.3, Z 114.3..117.7; barrier X 267.0, Z 114.4 |
| Sally Port (xe ra vào) | mặt Đông X 282, Z 20..38; dốc dẫn X 282.4..290.4, Z 18..40 — **giữ trống** |
| Cột cờ | (235, 90) |
| Sân trước (plaza) | X 224..298, Z 76.5..122.0, mặt sàn Y 1.34 |

## Ảnh kiểm tra (15)

`01_facade_front` · `02_diag_southwest` · `03_diag_southeast` · `04_aerial` · `05_side_west` ·
`06_side_east` · `07_lobby_interior` · `08_bullpen_interior` · `09_jail_corridor` ·
`10_night_facade` · `11_door_detail` · `12_garage_interior` · `13_roof_helipad` ·
`14_second_floor` · `15_parking`

Mọi ảnh đã được xem và các lỗi hình ảnh phát hiện đã sửa trong vòng QA này:
bảng hiệu bị đai đá che → hộp bảng hiệu nhô 1.2 studs + chữ neon nổi 0.4; chữ "LSPD" trên
huy hiệu tràn vòng → thu nhỏ; biển "SALLY PORT" bị tang cuốn che → hạ panel; panel trang trí
hai bên cửa bị cột che → thay bằng biển đồng trên 2 cột giữa; bàn thợ + bảng dụng cụ trong
garage chắn cửa cuốn (lộ nền trời) → dời sang tường Nam.
