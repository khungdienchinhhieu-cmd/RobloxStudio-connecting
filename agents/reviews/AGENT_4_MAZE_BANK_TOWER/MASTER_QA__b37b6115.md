# Master QA — AGENT_4_MAZE_BANK_TOWER

**Người nghiệm thu:** `Agent Chính` · branch `arena/b37b6115-robloxstudio-connecting`
**Bài nộp:** branch `arena/bc783dbc-robloxstudio-connecting` · commit `2fc5ca1`
**Ngày:** 2026-10-25
**Kết luận: ✅ DUYỆT (APPROVED) — 9.2 / 10** *(bài nộp gốc: 8.2/10, sau 3 bản vá của Agent Chính)*

---

## 1. Phạm vi bài nộp

| Hạng mục | Kết quả |
|---|---|
| File lõi bị sửa | **0** ✅ |
| `studio-sync.json` bị chạm | **Không** ✅ |
| Module mới | `src/shared/World/Modules/Plot_D2_MazeBankTower.luau` (1 882 dòng) |
| Ảnh nghiệm thu | 21 JPG (`01_hero_south_facade` … `21_floor_logo_detail`) |
| Ghi chú | `CLAIM` / `SUBMIT` / `AGENT_4_MAZE_BANK_TOWER__bc783dbc.md` |

Ô đất: `Plot_D2` — X −83..83, Z −199..−63, `groundY = 1.15`.

---

## 2. Compile

```
24/24 files compiled — 0 lỗi
Plot_D2_MazeBankTower.luau  106 175 B
```

`build()` chạy sạch trong harness (mock Roblox API), không `BUILD_ERROR`.

---

## 3. Số liệu hình học (sau vá — xem §6)

| # | Hạng mục | Kết quả | Gate |
|---|---|---|---|
| 1 | Tổng `BasePart` | **2 312** | 900–2 500 ✅ |
| 2 | Khối có HP ẩn | **2 270 / 2 312 = 98.18 %** | ≥ 90 % ✅ |
| 3 | `CanTouch = true` | **0** | ✅ |
| 4 | Khối nhỏ (`maxDim < 1.6`) còn `CanCollide` | **0** | ✅ |
| 5 | Sàn/mái mỏng rộng thiếu `CanCollide` | **0** | ✅ |
| 6 | `CastShadow = true` | 732 (31.7 %) | ≤ 40 % ✅ |
| 7 | Tràn biên ô đất | **0** | ✅ |
| 8 | Khối trùng hoàn toàn | **0** | ✅ |
| 9 | Khối lơ lửng (> 0.35 stud) | **0** (khe lớn nhất **0.15 stud**) | ✅ |
| 10 | Z-fighting lộ ra | **0** | ✅ |
| 11 | Vào được công trình | **Có** — sảnh + 2 cánh Đông/Tây | ✅ |

AABB: **X −83.00..83.00 · Y 1.15..165.00 · Z −188.00..−63.00** — tháp cao **165 studs, cao nhất thành phố**.

### Phân bố khối theo độ cao

| Dải Y | Số khối | Ghi chú |
|---|---|---|
| 0–10 | 967 | nền, sảnh, plaza, cánh đỗ xe |
| 10–20 | 453 | sảnh thông tầng + cánh |
| 20–30 | 154 | tầng kỹ thuật |
| 40–50 / 60–70 | 116 / 116 | thân tháp thu dần |
| 80–90 / 100–110 | 108 / 108 | |
| 120–145 | 163 | |
| 145–170 | 107 | vương miện + sân đáp |

---

## 4. Kiểm tra vỏ & lối đi

### Vỏ công trình — KÍN
Quét tia 4 mặt, tính cả kính: chỉ hở ở **cửa chính** (X ±8, mặt Nam Z = −104) và **cửa cuốn đỗ xe** hai cánh — đúng thiết kế.

### Lối đi — **ĐẠT sau khi vá** (xem §6.1)
Flood-fill trên lưới 0.5 stud, tính bán kính nhân vật **1.0 stud**:

| Điểm đích | Trước vá | Sau vá |
|---|---|---|
| Plaza trước đài phun nước | ✅ | ✅ |
| Sảnh trái / phải | ❌ | ✅ |
| Giữa sảnh | ❌ | ✅ |
| Cuối sảnh | ❌ | ✅ |
| Cánh Tây / Đông | ❌ | ✅ |

Vật cản còn lại duy nhất: `DeskFront` (quầy lễ tân) — **đúng kiến trúc**.

### Cầu thang
`GrandStairB`: 4 bậc, mỗi bậc cao **0.36 stud** (R15 leo thoải mái).

---

## 5. Kiểm tra thị giác (đọc 21 ảnh Agent tự render)

### Điểm mạnh
- **Thân tháp (`01`, `04`)**: 6 tầng kính thu dần đều, cột góc và diềm vàng gold, mullion dọc — đọc ra đúng dáng "Maze Bank Tower" mà vẫn gọn.
- **Vương miện (`15`, `17`)**: băng `MAZE BANK` phát sáng trên nền navy, ban công kính.
- **Sân đáp (`14`)**: vòng đáp đỏ/trắng + chữ H, đèn hiệu, cột ăng-ten.
- **Nội thất sảnh (`07`, `08`, `09`, `10`)**: sàn cẩm thạch bàn cờ, 4 cửa thang máy vàng, quầy lễ tân chữ L, đèn chùm khung vàng, ô trần phát sáng, logo `MAZE BANK` khảm sàn. Đây là nội thất tốt nhất từ đầu dự án.
- **2 cánh đỗ xe (`12`, `13`, `19`)**: pano `P — HẦM ĐỖ XE`, cửa cuốn 18 × 12, lam trang trí, dải neon.

### Lỗi phát hiện → đã vá (§6)
| Lỗi | Mô tả |
|---|---|
| **Không vào được công trình** | 2 cánh cửa kính `EntryDoorL/R` để `CanCollide = true` → sảnh **niêm phong hoàn toàn**. Toàn bộ nội thất công phu **không thể tiếp cận**. |
| Mái 2 cánh là "hố đen" | `Wing_RoofMembrane` dùng `C_ASPHALT` (54,56,62) trải **1 560 stud² mỗi bên** — nhìn từ trên cao như 2 tấm đen tuyền, tương phản gắt với toà nhà kem. |
| Sàn plaza bàn cờ | `Paver` xen kẽ 2 tông (178) / (150) — chênh **28/255 (11 %)**, đọc thành caro rõ ở góc trên cao. |
| Mái cánh trống trơn | Chỉ 36 khối trên 2 mái 1 560 stud² (2 cục AC + 1 biển mỗi bên). |

### Ghi chú nhỏ (không chặn duyệt)
- 42 khối `CanQuery = false` (sàn/trần lớn) — **không khối nào có máu ẩn** nên không ảnh hưởng cơ chế phá huỷ; là tối ưu hợp lệ.
- `MarbleTile` bàn cờ 2 tông chênh 62/255 — **cố ý** (đá cẩm thạch lát khảm), giữ nguyên.

---

## 6. Các bản vá Agent Chính đã áp dụng

### 6.1 Cửa chính khoá kín — **lỗi chặn, nghiêm trọng**
```diff
  box(fLob, "EntryDoorL", …, C_GLASS_LT, 45,
-     { material = Enum.Material.Glass, transparency = 0.18, castShadow = false, group = "EntryDoors" })
+     { material = Enum.Material.Glass, transparency = 0.18, castShadow = false, canCollide = false, group = "EntryDoors" })
```
Áp dụng cho cả `EntryDoorL` và `EntryDoorR`. Vẫn giữ **HP 45** nên bắn vỡ được như cũ.
Đây là **quy ước có sẵn của dự án** — `Plot_C3_MissionRowLSPD` (`ChiefDoorGlass`, `RoofDoorGlass`, `StallDoor`) và `Plot_C1_LSCustoms` (`OfficeDoorGlass`) đều dùng `canCollide = false` cho cửa kính.

Kết quả: sảnh + 2 cánh đỗ xe **vào được**, 6/6 điểm kiểm tra ĐẠT.

### 6.2 Mái 2 cánh đỗ xe
```diff
- C_ASPHALT (54,56,62) · Material.Asphalt
+ RGB(118,116,110)      · Material.Concrete
```
Kèm **11 chi tiết mái mỗi bên**: cửa sập mái + gờ, 4 ống thông hơi + 4 nắp chụp → mái hết trống.

### 6.3 Sàn plaza
```diff
- C_PAVE_DK = RGB(150,148,142)   -- chênh 28/255 so với C_PAVE
+ C_PAVE_DK = RGB(168,166,160)   -- chênh 10/255
```
Vẫn thấy mạch lát, hết hiệu ứng bàn cờ.

### 6.4 Z-fighting bậc thang
`GrandStairB_Step4` chồng lên mép `Terrace2` **0.06 stud** ở cùng cao độ 4.14 → dời cả thang **+0.06 stud** (`zLow −92.0 → −91.94`), bậc cuối kết thúc đúng mép.

---

## 7. Bảng điểm

| Tiêu chí | Trọng số | Bài nộp | Sau vá |
|---|---|---|---|
| Kiến trúc / bố cục | 20 % | 9.5 | 9.5 |
| Chi tiết & trang trí | 18 % | 8.5 | 9.0 |
| Hình học (kín, lơ lửng, z-fight) | 17 % | 9.5 | 9.5 |
| **Đi lại / vào được công trình** | 15 % | **3.0** | **9.5** |
| Hiệu năng | 12 % | 10 | 10 |
| Phá huỷ (`PartHealth`) | 8 % | 9.5 | 9.5 |
| Chất lượng thị giác | 7 % | 7.0 | 9.0 |
| Tuân thủ quy trình | 3 % | 10 | 10 |
| **Tổng** | | **8.2 / 10** | **9.2 / 10** |

**Xếp hạng:** công trình cao nhất & nội thất tốt nhất thành phố. Sau vá ngang tầm `Plot_C3_MissionRowLSPD` (9.0).

---

## 8. Bàn giao cho AGENT_5 / AGENT_6

| Hạng mục | Toạ độ |
|---|---|
| Tháp (footprint đế) | X −50..50, Z −182..−104 |
| Cánh đỗ xe Đông / Tây | X 62..83 / −83..−62, Z −178..−96 |
| Cửa chính | X −8..8 tại Z = −104 |
| Cửa cuốn đỗ xe | mặt ngoài 2 cánh (X = ±83), Z −150..−124 |
| Sân plaza 2 bậc | Y 2.70 và 4.14, Z −186..−63 |
| Đài phun nước | X −11.5..11.5, Z −91.5..−68.5 (giữ trống) |
| Đỉnh tháp | Y 165.00 |

---

## 9. Quyết định

**DUYỆT.** Module được tích hợp vào nhánh `arena/b37b6115-robloxstudio-connecting` và phát hành trong **Sync v15**.
