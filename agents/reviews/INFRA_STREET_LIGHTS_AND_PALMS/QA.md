# QA — `Infra_StreetLightsAndPalms` (AGENT_7_STREET_INFRASTRUCTURE)

Số liệu dưới đây lấy trực tiếp từ harness, không chép tay từ báo cáo.

## Lệnh kiểm (chạy lại được)

```bash
node tools/building_sim/run.cjs src/shared/World/Modules/Infra_StreetLightsAndPalms.luau
node tools/building_sim/overlap_check.cjs Infra_StreetLightsAndPalms
```

## Kết quả

| Hạng mục | Kết quả |
|---|---|
| BasePart | 2 283 |
| Khối có máu ẩn (`Destructible` + `PartHealth`) | 2 283 (100,0 %) |
| AABB | X −324,55 … +324,55 · Y 1,15 … 29,62 · Z −224,00 … +179,45 |
| Khối nhỏ < 1,6 còn `CanCollide` | 0 |
| `CanTouch = true` | 0 |
| `CastShadow` sai (kính / Neon) | 0 |
| `SurfaceGui` sai chuẩn | 0 (module không dùng SurfaceGui — chữ ghép khối 3D) |
| Khối size 0 | 0 |
| Tên part trùng | 0 / 2 283 |
| Cặp đè trong module (> 6 stud³) | 0 |
| Cặp đè với nền + 11 module công trình (30 137 part) | 0 |
| Khối chân/đế nằm trong lòng đường nhựa | 0 |
| Biên dịch Luau toàn repo | 44/44 |

## Attribute trên Folder gốc

`LampCount = 56` · `TrafficSignalCount = 10` · `PalmCount = 30` · `BenchCount = 9` ·
`BinCount = 13` · `HydrantCount = 24` · `PlanterCount = 9` · `BusStopCount = 6` ·
`SignalCycleSeconds = 40` · `PartPointLights = false` · `PlacedInDeclaredBounds = true`.

## Ba lỗi tự tìm ra và đã sửa trước khi nộp

| Lỗi | Bằng chứng | Cách sửa |
|---|---|---|
| 194 khối chân đứng trong lòng đường | đại lộ 4 làn rộng 48 stud nhưng lùi theo khổ 40 | lọc theo bảng `WorldGrid.EW_ROADS/NS_ROADS` + bán kính hạng mục → 0 |
| 2 đầu đèn tín hiệu chụm vào tim ngã tư | `SignalHeadHousing` của 2 cột cách nhau 4,3 stud | mỗi cột chỉ vươn cần 1 trục |
| Tàu lá cọ xếp thành đĩa phẳng | dịch tàu lá theo trục X cục bộ sai | toả 8 hướng, rủ 2 đốt |

## Ảnh

- `01_city_plan.png` — mặt bằng toàn thành phố, 153 dấu vị trí, chú giải khớp attribute.
- `02_asset_closeups.png` — 4 hạng mục, phối cảnh isometric từ OBB thật.
- `03_intersection_scene.png` — ngã tư Vespucci × Alta, bán kính 210 stud.
