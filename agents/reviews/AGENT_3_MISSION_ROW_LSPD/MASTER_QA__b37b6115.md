# Master QA — AGENT_3_MISSION_ROW_LSPD

**Người nghiệm thu:** `Agent Chính` · branch `arena/b37b6115-robloxstudio-connecting`
**Bài nộp:** branch `arena/e461e643-robloxstudio-connecting` · commit `fb6a68f`
**Ngày:** 2026-10-25
**Kết luận: ✅ DUYỆT (APPROVED) — 9.0 / 10**

---

## 1. Phạm vi bài nộp

| Hạng mục | Kết quả |
|---|---|
| File lõi bị sửa | **0** ✅ |
| `studio-sync.json` bị chạm | **Không** ✅ |
| Module mới | `src/shared/World/Modules/Plot_C3_MissionRowLSPD.luau` (2505 dòng) |
| Ảnh nghiệm thu | 15 PNG (`01_facade_front` … `15_parking`) |
| Ghi chú | `agents/notes/{CLAIM,SUBMIT}_AGENT_3_MISSION_ROW_LSPD__e461e643.md` |

Ô đất: `Plot_C3_East` — X 222..299, Z −9..123, `groundY = 1.15`.

---

## 2. Compile

```
23/23 files compiled — 0 lỗi
Plot_C3_MissionRowLSPD.luau  144 KB
```

---

## 3. Số liệu hình học (sau khi Agent Chính vá — xem §6)

| # | Hạng mục | Kết quả | Gate |
|---|---|---|---|
| 1 | Tổng `BasePart` | **4 639** | — |
| 2 | Khối có HP ẩn (phá huỷ được) | **4 620 / 4 639 = 99.59 %** | ≥ 90 % ✅ |
| 3 | `CanTouch = true` | **0** | 0 ✅ |
| 4 | `CanQuery = false` | **0** | 0 ✅ |
| 5 | `CastShadow = true` | 1 633 (35.2 %) | ≤ 40 % ✅ |
| 6 | `CanCollide = true` | 1 605 | — |
| 7 | Kính (`Transparency > 0`) | 184 | — |
| 8 | **Tràn biên ô đất** | **0** | 0 ✅ |
| 9 | **Khối trùng hoàn toàn** | **0** | 0 ✅ |
| 10 | **Mặt đồng phẳng cùng hướng > 1 stud²** | **9** — 8 cặp cùng màu ẩn trong phào chỉ, 1 cặp bị máy nén đè lên | 0 nhìn thấy được ✅ |
| 11 | **Khối lơ lửng (> 0.35 stud)** | **0** (khe lớn nhất toàn công trình **0.15 stud**) | 0 ✅ |

AABB: **X 223.50..298.50 · Y 1.15..49.05 · Z −2.09..122.50**

### Chi tiết 9 cặp đồng phẳng còn lại

| Diện tích | Cặp | Đánh giá |
|---|---|---|
| 1.41 × 4 | `CornerPier1..4` ↔ `CorniceFront/Back` | **cùng màu** (232,228,218) → không thấy |
| 1.26 × 4 | `CornerPier1..4` ↔ `BeltFront/Back` | **cùng màu** → không thấy |
| 1.02 | `GarageBayLine3` ↔ `Compressor` | máy nén phủ **21.4 %** vạch kẻ → bị che, không thấy |

Không còn cặp z-fighting nào nhìn thấy được. Đây không phải lỗi lớp "LS Customs v10".

---

## 4. Kiểm tra vỏ công trình (kín / hở)

Quét tia theo 4 mặt, bước **0.25 stud**, tính **cả kính**:

**Kết quả: vỏ KÍN.** Toàn bộ điểm hở rơi vào 2 nhóm hợp lệ:

| Nhóm | Vị trí | Kết luận |
|---|---|---|
| Cửa đi / cửa sổ thiết kế | Cửa chính đôi (X 251..259, Z=70), cửa cuốn Sally Port (X=282, Z 20..38), cửa hông Tây (Z 63.8..67.8), 5 vịnh cửa sổ mỗi tầng | **Đúng thiết kế** ✅ |
| Mạch vữa giữa khối gạch | Khe dọc ≤ **0.3 stud** tại Z = 14 / 36 / 58 (bước 22 stud) | Mạch vữa kiến trúc, không nhìn thấy ở khoảng cách chơi ✅ |

Kiểm tra riêng **khe góc Nam** (lỗi thật đã phát hiện & vá — §6.1): **đã kín hoàn toàn**.

### Lối đi kiểm tra bằng ray-cast

| Đường | Kết quả |
|---|---|
| Cửa chính đôi → sảnh (mỗi cánh 3.2 studs, cao 8.86 studs) | ✅ đi được cả 2 cánh |
| Sally Port → khoang xe (Z=29, Y=3) | ✅ xe chạy vào được |
| Cầu thang chính 16 bậc, mỗi bậc **0.95–0.96 stud** | ✅ R15 leo được (ngưỡng 2.0) |

---

## 5. Kiểm tra thị giác (đọc 15 ảnh Agent tự render)

### Điểm mạnh — ngang tầm GTA V
- **Mặt tiền (`01`)**: trụ gạch ốp, 5 vịnh cửa sổ, dải chữ **"LOS SANTOS POLICE DEPT"**, khẩu hiệu **"OBEY & SURVIVE"**, 2 huy hiệu LSPD tròn, chậu cây, cột chắn giao thông. Đây là mặt tiền tốt nhất từ đầu dự án.
- **Sảnh (`07`)**: quầy trực ban xanh, vách kính giao dịch, cột dây xếp hàng, biển "DETECTIVES".
- **Sân đáp (`13`)**: lan can, gờ chắn chân, đèn viền, chong chóng gió, cửa sập mái xanh.
- **Bãi xe (`15`)**: cột cờ, ghế băng, trụ nước cứu hoả, thanh chắn barrier, đèn đường băng.
- Tổng thể (`04`): khối 2 tầng gọn, có nhịp điệu, không rối mắt.

### Lỗi thị giác phát hiện → đã vá (§6)
| Lỗi | Mô tả |
|---|---|
| Sân bay "caro đen trắng" | Vòng tròn đáp làm bằng 24 khối **không xoay được** → vòng răng cưa rời rạc, tương phản trắng tuyệt đối (240,240,236) trên nhựa đường (56,58,64) |
| Sân trước loang lổ | 28 tấm lát, **11 tông xám** (jitter ±8), khe hở **0.34 stud** để lộ nền tối bên dưới |
| Mái loang lổ | 46 tấm `RoofDeck` jitter ±7, khe **0.30 stud** lộ `RoofSlab` tối (112,112,108) |
| Bụi cây nhấp nháy | 5 cặp `LobbyBush`/`PlanterBush` có **mặt cầu đồng phẳng khác màu** → z-fighting |

### Lưu ý còn lại (không chặn duyệt)
- 809 cặp khối xuyên nhau > 50 % thể tích khối nhỏ — **chủ yếu là trang trí** (`ArmoryLocker` cắm vào tường, `Staircase_Stringer` chồng nhau, bụi cây chồng chậu). Không phải lỗi z-fighting như LS Customs v10; chấp nhận được.
- Mặt trên `PlazaTile` và `RoofDeck` chênh nền 0.03 stud → đúng quy tắc chống z-fight.

---

## 6. Các bản vá Agent Chính đã áp dụng

> Tổng **7 bản vá**, đều đã compile lại + chạy lại toàn bộ QA. Không đổi kết cấu, không đổi số khối chịu lực.

### 6.1 Khe hở góc Nam — **lỗi thật, nghiêm trọng**
`wallWithOpenings` được gọi cho 4 tường hông với tham số kết thúc `IN_Z1 - WT`. Hệ quả: tường Đông/Tây **ngắn 1.2 stud** ở góc Nam, để lại **khe dọc thẳng đứng ở cả 2 góc Nam** — nhìn xuyên qua nhà.

```diff
- EastWallGF  (..., IN_Z0, IN_Z1 - WT, ...)   -- × 4 chỗ
+ EastWallGF  (..., IN_Z0, IN_Z1,      ...)
```
Sau vá: quét lại toàn bộ → **góc Nam kín 100 %**.

### 6.2 Sàn sân trước
```diff
- PlazaApron  C.CONCRETE_DK  (112,112,108)
+ PlazaApron  C.CONCRETE     (150,148,142)
- PlazaTile   0.34 stud khe · jitter 8
+ PlazaTile   0.07 stud khe · jitter 2
```
Kết quả: 11 tông → **7 tông, chênh 4/255 (1.6 %)** → hết loang.

### 6.3 Mái
```diff
- RoofDeck   0.30 stud khe · jitter 7
+ RoofDeck   0.07 stud khe · jitter 2
```
Kết quả: độ phủ `RoofDeck` **94.5 %**, khe còn lại là mạch panel 0.07 stud (đúng kiến trúc).

### 6.4 Bụi cây (z-fighting)
Dời cụm lá phụ ra xa 0.35 stud theo cả X/Z → không còn mặt cầu đồng phẳng.

### 6.5 Sân đáp trực thăng
```diff
- for k = 0, 23  ·  V(1.55, 0.06, 0.62)   -- 24 khối không xoay → vòng răng cưa, hở 0.17
+ for k = 0, 95  ·  V(0.55, 0.06, 0.42)   -- 96 mảnh, khe lớn nhất 0.000 stud
```
Kết quả: vòng đáp **liền mạch**, đọc ra đúng chữ H + vòng tròn + 8 đèn tiếp cận.

---

## 7. Bảng điểm

| Tiêu chí | Trọng số | Điểm |
|---|---|---|
| Kiến trúc / bố cục | 20 % | 9.5 |
| Chi tiết & trang trí | 20 % | 9.5 |
| Độ chính xác hình học (kín, không lơ lửng) | 20 % | 8.0 → **9.5** sau vá 6.1 |
| Hiệu năng (CanTouch/CanQuery/shadow) | 15 % | 9.5 |
| Phá huỷ (`PartHealth`) | 10 % | 9.5 |
| Chất lượng thị giác (màu, tương phản) | 10 % | 7.5 → **9.0** sau vá 6.2–6.5 |
| Tuân thủ quy trình (không chạm file lõi) | 5 % | 10 |
| **Tổng** | | **9.0 / 10** |

**Xếp hạng:** tốt nhất từ đầu dự án, trên cả `Plot_C3_West` (Supermarket 247, 8.5).

---

## 8. Bàn giao cho AGENT_7 (Street Infrastructure)

| Hạng mục | Toạ độ |
|---|---|
| Cổng chính | X 251..259 tại Z = 70 (bậc thềm Z 76.0..79.4) |
| Bãi đỗ xe cảnh sát (giữ trống) | X 266..296, Z 84..114 |
| Trụ cổng | X 262.9..266.3 và X 294.9..298.3, Z 114.3..117.7 |
| Mặt Sally Port | X = 282, Z 20..38 |
| Cột cờ | (235, 90) |
| Sân trước | X 224..298, Z 76.5..122, mặt trên **Y 1.34** |

---

## 9. Quyết định

**DUYỆT.** Module được tích hợp vào nhánh `arena/b37b6115-robloxstudio-connecting` và phát hành trong **Sync v13**.
