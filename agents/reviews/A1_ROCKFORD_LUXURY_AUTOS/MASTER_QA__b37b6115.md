# Master QA — A1_ROCKFORD_LUXURY_AUTOS (`Plot_D1`)

**Người nghiệm thu:** `Agent Chính` · branch `arena/b37b6115-robloxstudio-connecting`
**Bài nộp:** branch `arena/f3da0fbe-robloxstudio-connecting` · commit `28349d7`
**Ngày:** 2026-10-26
**Kết luận: ✅ DUYỆT (APPROVED) — 9.1 / 10**

---

## 1. Phạm vi bài nộp

| Hạng mục | Kết quả |
|---|---|
| File lõi bị sửa | **0** ✅ (chỉ thêm 1 module + tài liệu + ảnh) |
| `studio-sync.json` bị chạm | **Không** ✅ |
| Module mới | `src/shared/World/Modules/Plot_D1_RockfordShowroom.luau` (1 293 dòng) |
| Ảnh nghiệm thu | 15 PNG 1200 × 750 (`01_hero_south` … `15_second_floor`) |
| Ghi chú | `agents/notes/{A1_ROCKFORD_LUXURY_AUTOS,SUBMIT_A1_ROCKFORD_LUXURY_AUTOS}__f3da0fbe.md` |

Ô đất: `Plot_D1` — X −318…−134, Z −204…−60, nền `Y = 1.15`.
Công trình: **Luxury Autos** — showroom siêu xe 2 tầng + tầng lửng, mặt tiền kính cong
nhìn ra Olympic Fwy, sân trước 6 ô đỗ + barrier cổng.

---

## 2. Compile

```
37/37 files compiled — 0 lỗi
Plot_D1_RockfordShowroom.luau   ~52 KB · 1 293 dòng
```

---

## 3. Số liệu hình học — đo lại bằng harness của Agent Chính

Không tin báo cáo của agent phụ: dựng lại module trong **Luau VM thật** bằng
`tools/building_sim/run.cjs` (mock Roblox API có **ma trận xoay 3×3 thật**, `IsA` đúng
cây kế thừa, `GetDescendants` đệ quy), rồi đo từng `BasePart`.

| # | Hạng mục | Kết quả | Gate |
|---|---|---|---|
| 1 | Tổng `BasePart` tạo ra | **3 165** | 2 000–3 500 ✅ |
| 2 | Khối có HP ẩn (`Destructible` + `PartHealth > 0`) | **3 152 / 3 165 = 99,59 %** | ≥ 95 % ✅ |
| 3 | Khối cố ý không phá (móng/sàn/mái chịu lực) | 13 | thông tin |
| 4 | Khối nhỏ < 1,6 stud còn `CanCollide` | **0** | 0 ✅ |
| 5 | `CanTouch = true` | **0** | 0 ✅ |
| 6 | Kính / Neon còn `CastShadow` | **0** | 0 ✅ |
| 7 | `SurfaceGui` sai chuẩn (MaxDistance ≠ 340 / TextScaled / PixelsPerStud > 32) | **0** | 0 ✅ |
| 8 | Khối `size = 0` | **0** | 0 ✅ |
| 9 | Tên part trùng nhau | **0 / 3 165** | 0 ✅ |
| 10 | AABB (xoay thật) | X **−316,00 … −136,00** · Y **1,15 … 46,80** · Z **−191,45 … −61,10** | trong ô ✅ |
| 11 | Tràn biên ô đất / dưới nền | **0** | 0 ✅ |
| 12 | `PlotId` root đóng dấu | `Plot_D1` ✅ (ServiceManager sẽ tự bật quầy D1) | ✅ |

Lệnh tái lập:

```bash
node tools/building_sim/run.cjs src/shared/World/Modules/Plot_D1_RockfordShowroom.luau
node tools/building_sim/counter_check.cjs        # quầy dịch vụ có bị tường chắn không
```

---

## 4. Kiểm tra bằng mắt (4 ảnh đã xem)

| Ảnh | Nhận xét |
|---|---|
| `01_hero_south.png` | Mặt tiền kính cong 2 lớp đúng chất showroom; chữ Neon “LUXURY AUTOS · ROCKFORD HILLS · OLYMPIC FWY” rõ; sân trước 6 ô đỗ đánh số, barrier đỏ-trắng đang nâng, vạch sang đường, cột đèn, cọ cảnh |
| `04_aerial_overhead.png` | Giếng trời kính + 3 cục HVAC trên mái, diềm mái/nắp inox; sân trước bố trí đối xứng, hai bên có cây và ghế |
| `10_interior_atrium.png` | Sảnh thông tầng thật: 2 bục xoay + 3 xe mô hình, tầng lửng chữ U có lan can kính, quầy cà phê, bảng “CHÀO MỪNG ĐẾN VỚI LUXURY AUTOS” |
| `13_night_facade.png` | (đã lấy về, xem cùng bộ) — hệ neon ban đêm |

Không thấy khối lơ lửng, không thấy khối xuyên nhau ở các góc đã kiểm.

---

## 5. Đối chiếu bộ tiêu chí của dự án

| Yêu cầu | Kết quả |
|---|---|
| Một công trình / một lượt, cực chi tiết | ✅ 3 165 khối, 3 cao độ sử dụng được (trệt / lửng / 2) |
| Tỉ lệ 1:1 (`WorldGrid.meters()`) | ✅ thông thuỷ trệt 14,84 stud ≈ 4,46 m; tầng 2 11,20 stud ≈ 3,36 m |
| Cửa đi bộ ≥ 8 stud cao | ✅ 15,85 × 8,50 stud |
| Cửa cuốn xe ≥ 15 × 11 | ✅ 18,00 × 12,00 stud |
| Kính mặt tiền phá được, xe tông xuyên | ✅ 446 ô kính `integrity 40`, `CanCollide = false` |
| Không sửa file lõi | ✅ |
| Mọi công trình phải có chức năng | ✅ quầy `D1_SHOWROOM` (SPAWN_CAR $2 000) tự bật ở ô này |

---

## 6. Việc Agent Chính làm thêm khi tích hợp (không sửa module)

1. **Đặt lại 9 quầy dịch vụ** bằng công cụ giải tự động — nhiều quầy cũ nằm lọt trong
   tường/kính/cọc chắn (phát hiện nhờ `counter_check.cjs`), trong đó có `D1_SHOWROOM`.
2. **`ServiceManager.groundYAt()`** — quầy raycast xuống lấy mặt sàn thật (D1: **1,37**),
   không còn cứng 1,15.
3. Thêm `tools/building_sim/{prelude,run,counter_check}` để mọi bài nộp sau đều được đo
   độc lập như bài này.

---

## 7. Điểm trừ (nhỏ)

- Pylon hiệu “LUXURY AUTOS · PREMIUM MOTORS · SIMEON YETARIAN” đặt trước mặt kính,
  ở góc nhìn chính diện che mất một phần sảnh (~0,3 điểm).
- 3 xe trưng bày trong sảnh vẫn là khối hộp ghép (đúng phong cách dự án, nhưng chưa
  “siêu xe” như các chi tiết kiến trúc) (~0,2 điểm).

**Tổng: 9,1 / 10 — DUYỆT.** Đây là công trình thứ 5 của thành phố và là ô đất đầu tiên
hoàn thành trong vòng quét V6.
