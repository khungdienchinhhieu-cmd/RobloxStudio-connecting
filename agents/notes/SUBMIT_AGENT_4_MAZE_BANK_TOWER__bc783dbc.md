# 🟣 BÀN GIAO CHỜ NGHIỆM THU: `AGENT_4_MAZE_BANK_TOWER`
- **Nhánh Agent Phụ:** `arena/bc783dbc-robloxstudio-connecting`
- **Thời điểm nộp (Bộ Đàm):** 2026-10-25T12:22:21.431Z

**Tóm tắt nộp bài (Bộ Đàm):**

> THÁP TÀI CHÍNH MAZE BANK PLAZA & TOWER — Plot_D2, file DUY NHẤT src/shared/World/Modules/Plot_D2_MazeBankTower.luau (1882 dòng, --!strict). KHỐI LƯỢNG: 2292 BasePart, 2250 part có máu ẩn (98,2%) -> xe tông/súng bắn tự vỡ; 42 part kết cấu (sàn/mái). KIỂM ĐỊNH: 0 lỗi Luau, 0 part ngoài biên (X -83..83, Y 1.15..165.00, Z -188..-63), 0 part lơ lửng, 0 trùng hình học, 0 trùng tên, 0 cặp mặt phẳng z-fighting lộ thiên, 0 part nhỏ còn CanCollide, 0 CanTouch, 0 kính/neon còn CastShadow, 0 SurfaceGui sai MaxDistance, 0 TextScaled. TOẠ ĐỘ KHỚP NỐI: (1) CỔNG + LỐI BỘ HÀNH CHÍNH X=0, hàng rào Z=-65.0 (khẩu cổng X -9.5..9.5), cửa đôi kính 16 x 8.8 studs tại Z=-104, sàn sảnh Y=4.20; (2) CỬA CUỐN XE PHÍA TÂY X=-82.45, Z=-149 (18 x 12) ra Alta St; (3) CỬA CUỐN XE PHÍA ĐÔNG X=+82.45, Z=-149 (18 x 12) ra San Andreas Ave; (4) BÃI ĐÁP TRỰC THĂNG X=0, Z=-143, D=30, cao độ 155.1; đỉnh cột ăng-ten 164.00. Chừa trống dải Z -63..-66.5 X -9.5..9.5 cho Agent 7 StreetProps và Z -158..-140 sát vỉa hè 2 bên cho Agent 3 Traffic. NỘI THẤT FULL: sàn cẩm thạch khảm + huy hiệu logo 13x13, quầy lễ tân chữ L + 3 bàn + 3 màn hình, 4 thang máy kính + bảng tầng tiếng Việt, cổng dò kim loại + 4 turnstile, 2 cụm sofa da + thảm, 2 tranh ốp tường, đèn chùm 2 tầng + 20 tấm đèn trần, biển vàng MAZE BANK, mái che lối vào 26 studs. Hầm đỗ xe: 12 cột, 2 dãy vạch đỗ, 3 mũi tên làn, gờ chặn bánh, buồng bán vé, 6 đèn + 3 quạt trần. 21 ảnh render đã kiểm tra bằng mắt tại agents/reviews/AGENT_4_MAZE_BANK_TOWER/. Chi tiết + bảng số liệu ở phần 1–3 bên dưới.

---

- **Nhánh Agent Phụ:** `arena/bc783dbc-robloxstudio-connecting`
- **File DUY NHẤT được tạo:** `src/shared/World/Modules/Plot_D2_MazeBankTower.luau` (1882 dòng, `--!strict`)
- **Không sửa file lõi nào** (WorldGrid / PartBuilder / CityFoundation / DistrictRegistry / DestructionManager / init.* / GtaHud …), không commit `studio-sync.json`.
- **Ảnh kiểm định:** `agents/reviews/AGENT_4_MAZE_BANK_TOWER/` — 21 ảnh (mặt đứng, 2 góc chéo, trên cao, 2 mặt bên, 5 ảnh nội thất, cổng, cửa cuốn, sân thượng, ban đêm, chi tiết).

---

## 1. THÔNG SỐ KIỂM ĐỊNH (số đo thật, không ước lượng)

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| Tổng số BasePart | **2 292** | đo bằng mock Roblox + `PartBuilder` thật |
| Part có máu ẩn (`Destructible = true`) | **2 250 — 98,2 %** | mỗi ô kính / viên gạch / món đồ một bể máu riêng |
| Part kết cấu (`Destructible = false`) | **42** | 6 sàn tầng + 4 mảng mái sảnh + 4 sàn sân thượng/tầng + nắp MECH + bãi đáp + các dầm đỡ |
| Lỗi biên dịch Luau | **0** | `--!strict`, kiểm bằng `@luau-rs/luau` (syntax + chạy thật `Module.build`) |
| AABB tổng | X **−83,00 .. 83,00** · Y **1,15 .. 165,00** · Z **−188,00 .. −63,00** | nằm gọn trong ô Plot_D2 (X −83..83, Z −199..−63) |
| Part ra ngoài biên | **0** | |
| Part lơ lửng (dung sai 0,16 stud) | **0** | kiểm bằng tiếp xúc 3 trục + lồng nhau thể tích |
| Hình học trùng khít (trùng vị trí + kích thước) | **0** | |
| Tên part trùng nhau | **0** | mọi part có tên duy nhất |
| Cặp mặt phẳng đồng phẳng “lộ thiên” (z-fighting) | **0** | 1 685 cặp đồng phẳng còn lại đều là **mối nối kín** (mặt bị che, ≥85 % diện tích, sau khi ghép khối) |
| Cặp chồng lấn một phần (PARTIAL) | **0** | |
| Part nhỏ < 1,6 stud mà vẫn `CanCollide` | **0** | |
| Part `CanTouch = true` | **0** | toàn bộ đặt `CanTouch = false`, `EnableFluidForces = false` |
| Part kính / neon / nhỏ còn `CastShadow` | **0** | |
| `SurfaceGui` sai `MaxDistance` (≠340) | **0** | 26 part có GUI, 57 nhãn chữ |
| `TextScaled = true` | **0** | toàn bộ dùng `TextSize` cố định |
| Canvas GUI vượt 1100 px | **0** | `PixelsPerStud` ≤ 32 (tự hạ theo cạnh ngắn) |
| Sàn trùng mặt nền Y = 1,15 | **0** | sàn plaza 1,22 · sàn sảnh 4,20 · sàn hầm 1,75 → không có mặt phẳng nào trùng 1,15 |
| Vật liệu | Metal 996 · Glass 290 · Concrete 232 · Marble 212 · Neon 164 · Brick 152 · … | |
| Máu ẩn | 25 (đèn/lá cờ) … 480 (dầm chịu lực) | |

### Kích thước đáp ứng quy chuẩn

| Quy chuẩn | Yêu cầu | Thực tế |
|---|---|---|
| Cửa đi bộ (R15 = 5,45 stud) | cao ≥ 8,0 | cửa đôi kính sảnh **16 × 8,8 studs** (X −8..8, Z = −104) |
| Cửa cuốn ô tô (xe 8,2 × 7,0) | ≥ 15 × 11 | **18 × 12 studs** cả 2 cánh (X ≈ ±82,45, Z = −149) |
| Trần sảnh | ≥ 14 | **19,0 studs** (sàn 4,20 → trần 23,20) |
| Trần hầm đỗ xe | ≥ 14 | sàn hầm 1,75 → mặt dưới trần 15,85 = **14,1 studs** (xe cao 7,0 → dư 7,1) |
| Chiều cao công trình | ≥ 120 | đỉnh cột ăng-ten **164,00** (đỉnh khối tháp 143,20 + MECH 153,20 + nắp 155,10) |

---

## 2. TOẠ ĐỘ KHỚP NỐI (báo cho Agent Chính và Agent 7 StreetProps)

**Attribute trên Folder gốc `Plot_D2_MazeBankTower`:**

| Attribute | Giá trị |
|---|---|
| `PlotId` / `ModuleId` | `Plot_D2` / `Plot_D2_MazeBankTower` |
| `TowerHeightStuds` | `164.00` |
| `MainEntrance` | `X=0, Z=-65` (cổng chính rộng 16,4 studs trên Olympic Fwy) |
| `LobbyDoors` | `X 0, Z=-104` (cửa đôi kính 16 × 8,8 studs) |
| `VehicleRampWest` | `X=-83, Z=-149` (cửa cuốn 18 × 12, mặt Tây ra Alta St) |
| `VehicleRampEast` | `X=+83, Z=-149` (cửa cuốn 18 × 12, mặt Đông ra San Andreas Ave) |
| `Helipad` | `X=0, Z=-143`, đường kính 30 studs, cao độ **155,1** |
| `DestructibleStore` | `true` |

**Chi tiết cho Agent 7 (StreetProps) / Agent 3 (Traffic):**

- **Lối vào bộ hành chính:** trục X = 0, từ vỉa hè Z ≈ −63,4 đi qua cổng (Z = −65,0) → sân 2 bậc (T1 2,70 · T2 4,14) → 3 bậc tam cấp → sàn sảnh 4,20. **Chừa trống dải Z −63,0 .. −66,5, X −9,5 .. 9,5.**
- **Hai lối xe:** mặt ngoài tường cánh X = **−82,45** (Tây) và **+82,45** (Đông), tim cửa Z = −149,0, khẩu độ 18 × 12, có mái che + biển chữ nhật “P · HẦM ĐỖ XE · MAZE BANK”. **Chừa trống Z −158,0 .. −140,0 sát vỉa hè hai bên** để xe vào cua.
- **Vỉa hè/đèn đường của Agent 7** nên đặt ngoài X ±83 / Z −63 (sân đã có 10 cọc chắn + 4 đèn sân + 4 cột cờ riêng ở Z −69, X ±56/±70).
- **Mặt bằng kín:** hàng rào đá cao 2,70 + trụ đá mỗi 18 studs chạy suốt mặt Nam Z = −65,0 (chừa khẩu cổng X −9,5..9,5). Không cần thêm hàng rào.

---

## 3. MÔ TẢ CÔNG TRÌNH

**THÁP TÀI CHÍNH MAZE BANK PLAZA & TOWER** — Plot_D2 (PILLBOX HILL), phong cách trụ sở ngân hàng Los Santos: đá cẩm thạch trắng + vàng kim + kính xanh đậm.

- **Quảng trường (01_Plaza):** 2 bậc sân, đài phun nước bán nguyệt có huy hiệu tròn + vòi phun neon, 4 chậu cây lớn (mỗi chậu: chậu + vành + đất + thân + 3 tầng tán), 4 cột cờ, 10 cọc chắn, 4 đèn sân cầu, ghế đá, thùng rác, paver 2 màu.
- **Bệ (02_Podium):** đế đá 2 tầng (T1 ±60 · T2 ±56) bọc quanh tháp, ban công đá + lan can, 4 chậu cây trên tầng 2.
- **Sảnh giao dịch (03_Lobby) — thông tầng 19 studs:** sàn cẩm thạch 100 ô caro + đường chỉ vàng + **huy hiệu logo MAZE BANK 13 × 13 studs** (SurfaceGui mặt trên), 6 cột đá + đầu cột vàng, **quầy lễ tân chữ L** (mặt granite + 3 bàn làm việc + 3 màn hình + ghế), **4 thang máy kính** + bảng tầng 7 dòng tiếng Việt, **cổng dò kim loại + 4 turnstile**, 2 cụm sofa da + bàn + thảm + cây trong nhà, 2 tranh ốp tường, **đèn chùm 2 tầng khung vàng + 8 bóng**, lưới 20 tấm đèn trần neon, biển vàng “MAZE BANK” trên tường hậu, mái che lối vào 26 studs + 2 cột inox + diềm tên toà nhà, cửa đôi kính + tay nắm + thảm chùi chân.
- **Thân tháp (04_Tower):** 6 tầng kính thu dần 2 studs mỗi cạnh (L1 ±47 → L6 ±37), **mỗi tầng cao 20 studs**, trụ góc vàng bậc thang, mỗi mặt chia ô kính theo nhịp 8 studs (mỗi ô một bể máu 45), mullion nhôm, lam đứng vàng, diềm ngang trên/dưới, **sân thượng từng tầng có sàn đua + lan can đá + dải LED vàng**, bảng tên tầng tiếng Việt (TẦNG 2 · DỊCH VỤ … TẦNG 7 · KỸ THUẬT), tầng kỹ thuật MECH ±24 với lam thông gió, **băng chữ “MAZE BANK · PILLBOX HILL · LOS SANTOS” 4 mặt** + diềm vương miện.
- **Sân thượng (05_RoofHelipad):** sàn mái, nắp buồng kỹ thuật đua 2 studs + diềm vàng, **bãi đáp trực thăng tròn 30 studs** (20 dải + vòng đỏ/trắng + chữ H + 12 đèn viền), 5 cục nóng + quạt, tháp nước, hộp thông gió, cửa sập mái, **cột ăng-ten cao tới 164,00** (móng + bệ + 2 đoạn cột + 3 thanh ngang + 2 chảo parabol + đèn báo đỏ neon + PointLight).
- **2 cánh hầm đỗ xe (06/07_Wing):** sàn hầm + 3 bậc dốc, **cửa cuốn 18 × 12** (9 nan, mỗi nan một bể máu, 2 ray dẫn + hộp đầu + mô tơ + băng cảnh báo vàng/đen), 12 cột (base/shaft/cap/đèn), 2 dãy vạch đỗ + 3 mũi tên làn + gờ chặn bánh, trần + 9 đèn + 4 quạt, buồng bán vé + máy bán vé + cọc nón + phuy, mái + lan can + 2 cục nóng, **bảng hiệu mái 2 mặt trên 2 cột**, mặt phố có nẹp vàng + lam + pano, mặt đầu hồi có pano “P · HẦM ĐỖ XE”.
- **Cổng (08_Gate):** tường rào đá 2,70 + đỉnh vàng + trụ đá + hàng rào cây, **2 trụ cổng 2,8² × 5,6** + đai vàng + chụp đèn neon, **2 cánh cổng khung sắt 9 song** mở vào trong, **đà ngang + biển “MAZE BANK PLAZA”** (mặt ngoài) / “CHÀO MỪNG QUÝ KHÁCH” (mặt trong), thảm nhựa + 4 vạch sang đường.

**Chữ trong game:** toàn bộ tiếng Việt có dấu (trừ tên riêng “MAZE BANK”, “PILLBOX HILL”, “LOS SANTOS”).
