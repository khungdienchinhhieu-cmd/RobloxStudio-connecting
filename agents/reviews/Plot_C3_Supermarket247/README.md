# 📸 Ảnh Nghiệm Thu — Siêu Thị Tiện Lợi 24/7 (`Plot_C3_West`)

**Task:** `AGENT_2_SUPERMARKET_247` · **File:** `src/shared/World/Modules/Plot_C3_Supermarket247.luau`

Ảnh render 3D sinh trực tiếp từ module `.luau` thật (chạy qua `@luau-rs/luau` WASM với
mock Roblox + `PartBuilder.luau` thật), rasterize z-buffer bằng Pillow/numpy.

| # | File | Góc nhìn |
|:-:|:--|:--|
| 1 | `01_hero_southeast.jpg` | Toàn cảnh từ Đông-Nam: mặt tiền kính, mái hiên sọc, biển chính, bãi đỗ |
| 2 | `02_front_elevation.jpg` | Chính diện mặt Nam: biển 3 dòng, cửa đôi, pylon trên nóc |
| 3 | `03_west_loadingbay.jpg` | Mặt Tây: cửa cuốn kho hàng 16×12 + bến bốc dỡ + biển RECEIVING |
| 4 | `04_aerial_sw.jpg` | Trên cao: bố cục mái, 2 pylon, HVAC, lan can mái |
| 5 | `05_night_signage.jpg` | Ban đêm: neon biển hiệu + đèn đường phát sáng |
| 6 | `06_interior_from_door.jpg` | Nội thất nhìn từ cửa chính vào |
| 7 | `07_interior_to_door.jpg` | Nội thất nhìn từ trong ra: kệ gondola + biển AISLE + đèn tuýp |
| 8 | `08_interior_checkout.jpg` | Khu thu ngân 3 làn + biển CHECKOUT · THU NGÂN |
| 9 | `09_interior_aisles.jpg` | Lối đi giữa các dãy kệ |
| 10 | `10_interior_coolers.jpg` | Dàn tủ lạnh nước ngọt phát sáng + biển COLD DRINKS |

## Kết quả kiểm định tự động

| Hạng mục | Kết quả |
|:--|:--|
| Luau strict (`@luau-rs/luau` analysis, lint bật) | **0 lỗi / 0 cảnh báo** |
| Compile & chạy thật module + `PartBuilder` | ✅ 934 BasePart |
| Buildable Bounds (X 137..212, Z 20..123) | ✅ X 137.0–212.0, Z 26.95–123.0 |
| Cao độ nền `groundY = 1.15` | ✅ Thấp nhất 1.15, mặt sàn hoàn thiện 1.60 (không Z-fight) |
| Part lơ lửng (không tiếp xúc khối nào) | ✅ **0** |
| Khe hở nan cửa cuốn | ✅ **0.000** studs |
| Cửa đi bộ | ✅ 9.0 studs (≥ 8.0) |
| Cửa cuốn ô tô | ✅ 16 × 12 studs (≥ 15 × 11) |
| Chiều cao trần | ✅ 15.0 studs (≥ 14) |
| Máu ẩn `integrity` | ✅ 933/934 part (chỉ tấm móng sàn là `Destructible = false`) |
