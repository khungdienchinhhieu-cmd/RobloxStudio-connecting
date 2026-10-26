# 🏙️ PROMPT 3 AGENT PHỤ — QUÉT SẠCH THÀNH PHỐ (bản v6 · 2026-10-26)

> **Mục tiêu:** dựng **6 công trình còn trống** để hoàn thiện toàn bộ Los Santos.
> Mỗi Agent phụ làm **MỘT công trình một lần** — chi tiết như LS Customs (1 800–4 500 khối),
> xong → PR → Agent Chính nghiệm thu → mới sang công trình tiếp theo (**2 vòng/agent**).
>
> **Cách dùng:** mở 3 tab Arena.ai song song, kết nối cùng repo, mỗi tab dán **đúng 1 thẻ việc**
> bên dưới (thẻ đã bao gồm toàn bộ luật chung, không cần dán thêm gì).

---

## 📋 PHÂN CÔNG

| Agent | Vòng 1 | Vòng 2 |
| :--- | :--- | :--- |
| **A** | `A1_ROCKFORD_LUXURY_AUTOS` — Showroom siêu xe (`Plot_D1`) | `A2_LITTLE_SEOUL_DINER` — Quán nướng Hàn 2 tầng (`Plot_E3`) |
| **B** | `B1_VINEWOOD_CINEMA` — Rạp phim Vinewood (`Plot_D3`) | `B2_RICHMAN_GALLERIA` — TTTM Richman Galleria (`Plot_E4`) |
| **C** | `C1_LA_MESA_GARAGE` — Garage độ xe công nghiệp (`Plot_E2`) | `C2_PACIFIC_BLUFFS_VILLA` — Biệt thự chi tiết (`Plot_E1`) |

Sau khi cả 3 xong 2 vòng → **10/10 ô đất có công trình**, thành phố hoàn chỉnh.

---

## ⚠️ LUẬT CHUNG (mọi thẻ việc đều đã nhúng sẵn — đọc kỹ)

1. **Toạ độ là toạ độ THẬT của lưới v22** — dựng trực tiếp, **KHÔNG** dùng `WorldGrid.RELOCATION`
   (bảng đó chỉ dành cho 3 công trình cũ dựng từ lưới đường cũ).
2. **Tỉ lệ 1:1 ngoài đời:** `1 m = 3,33 stud` (`WorldGrid.STUDS_PER_METER`). Mọi kích thước viết
   `WorldGrid.meters(<mét>)`. Tầng nhà **11 stud (3,3 m)**, cửa đi **≥ 8 stud**, trần trong **≥ 14 stud**,
   cửa garage **≥ 15 × 11 stud**.
3. **Kiểu dựng = CHI TIẾT như cũ**, KHÔNG dùng kiểu "nhà ít part" (`DestructibleShell` chỉ dùng cho
   *tấm vỏ / panel kính*, không dùng để dựng cả căn nhà).
4. **Máu ẩn:** mọi khối dựng qua `PartBuilder` (`Destructible = true`). Tỉ lệ phá huỷ **≥ 95 %**.
5. **Không sửa file lõi** — chỉ tạo **1 file** `src/shared/World/Modules/<FILE>.luau`.
   TUYỆT ĐỐI không commit `studio-sync.json`.
6. **Hiệu năng:** part nhỏ (< 1.6 stud) `CanCollide = false`; mọi part `CanTouch = false`;
   kính/neon `CastShadow = false`; sàn & mái mỏng rộng LUÔN `CanCollide = true`;
   `SurfaceGui` đặt `MaxDistance = 340`, không `TextScaled`.
7. **Tự QA bằng số** (AABB, đếm part, % phá huỷ, khối trùng, khối lơ lửng) + **≥ 8 ảnh render**.
8. **Submit:** commit → push nhánh riêng → `node bridge/agent-radio.mjs submit <TASK_ID> "..."` →
   mở PR về `main` (**KHÔNG merge**) → dừng chờ nghiệm thu.

---

## 🅰️ A1 — SHOWROOM SIÊU XE ROCKFORD (Vòng 1)

```text
Bạn là WORKER AGENT của dự án "GTA V Los Santos Modular" (Roblox, Rojo + Studio Live Bridge).
Agent Chính chạy ở nhánh `arena/b37b6115-robloxstudio-connecting`.

===== BOOTSTRAP =====
1. git fetch origin "+refs/heads/*:refs/remotes/origin/*" --prune
   git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting
2. Đọc: `MULTI_AGENT_SYSTEM.md` → `docs/PERFORMANCE.md` → `agents/AGENT_TASK_BOARD.json`
   → `src/shared/WorldGrid.luau` (lấy `WorldGrid.meters`, `PLOTS`) → `src/shared/World/PartBuilder.luau`
   → tham chiếu chất lượng ĐẠT: `src/shared/World/Modules/Plot_C1_LSCustoms.luau`.
3. node bridge/agent-radio.mjs read
   node bridge/agent-radio.mjs say A1_ROCKFORD_LUXURY_AUTOS "Nhận Plot_D1 — bắt đầu dựng"

===== NHIỆM VỤ =====
<TASK_ID> = A1_ROCKFORD_LUXURY_AUTOS
Công trình : Showroom Siêu Xe "Luxury Autos" (Rockford Hills) — 2 tầng + tầng lửng
Ô đất     : Plot_D1 — X từ -318 đến -134, Z từ -204 đến -60  (184 × 144 stud = 55 × 43 m)
File      : src/shared/World/Modules/Plot_D1_RockfordShowroom.luau
PlotId    : "Plot_D1"   (BẮT BUỘC đúng tên này trong spec module)
Mặt nền   : Y = 1.15. Dựng TRỰC TIẾP ở toạ độ trên (KHÔNG dùng WorldGrid.RELOCATION).
Ngân sách : 2 000 – 3 200 khối, ≥ 95 % có máu ẩn.

KIẾN TRÚC BẮT BUỘC:
- Mặt tiền kính cong 2 lớp cao ≥ 16 stud, nhìn ra Olympic Fwy (phía Z = -60), khung thép trắng.
  Kính chia ô, mỗi ô 1 khối có máu ẩn integrity ~40 → XE TÔNG XUYÊN KÍNH được.
- Sảnh trưng bày thông tầng: sàn đá bóng (SmoothPlastic + Reflection), 2 bục xoay tròn có đèn rọi,
  3 xe mô hình tĩnh (dựng bằng khối, KHÔNG spawn xe thật), cầu thang cong lên tầng lửng.
- Tầng lửng: phòng làm việc kính của quản lý, sofa da, kệ mô hình xe, quầy cà phê nhỏ.
- Sân trước: 6 ô đỗ có vạch vàng, gờ chặn bánh, cổng barrier đỏ-trắng nâng hạ được (chỉ animation
  bằng CFrame trong lúc build, không cần script chạy).
- Biển hiệu "LUXURY AUTOS" chữ nổi Neon trắng, có SurfaceGui tên showroom.
- Cây cọ + bồn hoa dọc 2 bên lối vào; đèn sân 4 cột.

TỰ QA (in ra số liệu thật):
- tổng BasePart · số Destructible · % phá huỷ
- min/max X, Y, Z (phải nằm TRỌN trong X -318..-134, Z -204..-60)
- số cặp mặt phẳng đồng phẳng (0) · khối trùng (0) · khối lơ lửng (0)
- cửa đi rộng × cao, cửa garage rộng × cao
- ≥ 8 ảnh render vào `agents/reviews/A1_ROCKFORD_LUXURY_AUTOS/`

SUBMIT: commit `feat(A1): showroom Luxury Autos` → push nhánh của bạn →
node bridge/agent-radio.mjs submit A1_ROCKFORD_LUXURY_AUTOS "<số khối> khối, QA 0 lỗi" →
mở PR về main (KHÔNG merge) → DỪNG chờ Agent Chính nghiệm thu.
```

---

## 🅰️ A2 — QUÁN NƯỚNG HÀN LITTLE SEOUL (Vòng 2 · chỉ làm SAU khi A1 được duyệt)

```text
<TASK_ID> = A2_LITTLE_SEOUL_DINER
Công trình : Quán nướng Hàn Quốc "Seoul Garden" 2 tầng + sân hiên
Ô đất     : Plot_E3 — X từ -536 đến -358, Z từ -12 đến 128  (178 × 140 stud = 53 × 42 m)
File      : src/shared/World/Modules/Plot_E3_LittleSeoulDiner.luau
PlotId    : "Plot_E3"
Mặt nền   : Y = 1.15 · dựng trực tiếp · ngân sách 1 800 – 2 800 khối, ≥ 95 % máu ẩn.

KIẾN TRÚC BẮT BUỘC:
- Tầng trệt: 12 bàn nướng (mỗi bàn có chậu than + ống hút khói lên trần), quầy bar gỗ, tủ kính
  trưng bày banchan, bếp mở phía sau có 2 bếp gas + chụp hút.
- Tầng 2: 8 phòng riêng có vách gỗ trượt, hành lang hẹp, cửa sổ nhìn ra phố.
- Mái: sân hiên có 6 bàn ngoài trời + dù che + dây đèn Neon Hàn Quốc.
- Mặt tiền: biển hiệu 2 lớp "SEOUL GARDEN 서울가든" (Neon hồng + trắng), rèm cửa, bảng menu đèn.
- Hẻm bên hông: 3 thùng rác, 2 điều hoà ngoài, cầu thang thoát hiểm sắt.
- Chi tiết nhỏ: 6 chậu cây, 4 đèn lồng giấy, gạch lát vỉa hè riêng trước quán.

QA + SUBMIT: y hệt A1, đổi mã thành A2_LITTLE_SEOUL_DINER.
```

---

## 🅱️ B1 — RẠP PHIM VINEWOOD (Vòng 1)

```text
Bạn là WORKER AGENT của dự án "GTA V Los Santos Modular" (Roblox, Rojo + Studio Live Bridge).
Agent Chính chạy ở nhánh `arena/b37b6115-robloxstudio-connecting`.

===== BOOTSTRAP =====  (y hệt A1: fetch, merge, đọc tài liệu, radio)
node bridge/agent-radio.mjs say B1_VINEWOOD_CINEMA "Nhận Plot_D3 — bắt đầu dựng"

<TASK_ID> = B1_VINEWOOD_CINEMA
Công trình : Rạp chiếu phim "Vinewood Cinema" — Art Deco 2 tầng + khán phòng
Ô đất     : Plot_D3 — X từ 134 đến 318, Z từ -204 đến -60  (184 × 144 stud = 55 × 43 m)
File      : src/shared/World/Modules/Plot_D3_VinewoodCinema.luau
PlotId    : "Plot_D3"
Mặt nền   : Y = 1.15 · dựng trực tiếp · ngân sách 2 400 – 3 600 khối, ≥ 95 % máu ẩn.

KIẾN TRÚC BẮT BUỘC:
- Mặt tiền Art Deco ĐỐI XỨNG: 2 tháp đèn hai bên + mái vòm giữa, bảng Marquee Neon lớn
  chữ "VINEWOOD" + dòng phim đang chiếu (đổi được bằng attribute `NowShowing`).
- Thảm đỏ từ vỉa hè vào sảnh, 2 quầy vé tròn, cổng soát vé, 4 poster phim 2 bên.
- Sảnh chính: quầy bắp rang + nước ngọt (máy bắp có hạt bên trong), đèn chùm vàng, gương lớn.
- Khán phòng: màn chiếu ≥ 26 × 12 stud, 6 hàng ghế nhung đỏ xếp bậc thang (mỗi ghế 4–6 khối
  có máu ẩn), lối đi giữa, đèn sàn phát sáng dẫn lối, loa treo tường.
- Ngoài trời: cột mốc "WALK OF FAME" có 3 ngôi sao vàng trên vỉa hè + 2 cây cọ.

QA + SUBMIT: y hệt A1, mã B1_VINEWOOD_CINEMA.
```

---

## 🅱️ B2 — TTTM RICHMAN GALLERIA (Vòng 2 · chỉ làm SAU khi B1 được duyệt)

```text
<TASK_ID> = B2_RICHMAN_GALLERIA
Công trình : Trung tâm thương mại "Richman Galleria" — 3 tầng + giếng trời
Ô đất     : Plot_E4 — X từ 358 đến 536, Z từ -12 đến 128  (178 × 140 stud = 53 × 42 m)
File      : src/shared/World/Modules/Plot_E4_RichmanGalleria.luau
PlotId    : "Plot_E4"
Mặt nền   : Y = 1.15 · dựng trực tiếp · ngân sách 2 800 – 4 500 khối, ≥ 95 % máu ẩn.

KIẾN TRÚC BẮT BUỘC:
- Khối nhà 3 tầng khoét giếng trời giữa (atrium), mái kính nghiêng 2 lớp, khung nhôm đen.
- Tầng trệt: 8 gian hàng nhỏ (mỗi gian có quầy + kệ + biển hiệu riêng), đại sảnh đá cẩm thạch,
  cầu thang cuốn 2 chiều (dựng bằng 40–60 khối bậc thang cong), thang máy kính.
- Tầng 2: khu thời trang — 10 ma-nơ-canh (mỗi ma-nơ-canh 8–10 khối), phòng thử đồ 3 buồng.
- Tầng 3: khu ăn uống — 8 bàn + quầy food court + ban công nhìn xuống atrium.
- Ngoài: 2 cây cọ lớn, 4 băng ghế đá, bảng LED "RICHMAN GALLERIA" chạy chữ (SurfaceGui).

QA + SUBMIT: y hệt A1, mã B2_RICHMAN_GALLERIA.
```

---

## 🅲 C1 — GARAGE ĐỘ XE LA MESA (Vòng 1)

```text
Bạn là WORKER AGENT của dự án "GTA V Los Santos Modular" (Roblox, Rojo + Studio Live Bridge).
Agent Chính chạy ở nhánh `arena/b37b6115-robloxstudio-connecting`.

===== BOOTSTRAP =====  (y hệt A1)
node bridge/agent-radio.mjs say C1_LA_MESA_GARAGE "Nhận Plot_E2 — bắt đầu dựng"

<TASK_ID> = C1_LA_MESA_GARAGE
Công trình : Garage độ xe công nghiệp "La Mesa Customs" — nhà xưởng 1 tầng cao + phòng sơn
Ô đất     : Plot_E2 — X từ 358 đến 536, Z từ -204 đến -60  (178 × 144 stud = 53 × 43 m)
File      : src/shared/World/Modules/Plot_E2_LaMesaGarage.luau
PlotId    : "Plot_E2"
Mặt nền   : Y = 1.15 · dựng trực tiếp · ngân sách 2 000 – 3 200 khối, ≥ 95 % máu ẩn.

KIẾN TRÚC BẮT BUỘC:
- Nhà xưởng khung thép: 6 cột I-beam, vì kèo mái, tôn sóng, 2 cửa cuốn lớn ≥ 15 × 11 stud.
- 3 khoang nâng xe (mỗi khoang có cầu nâng 2 trụ, bảng điều khiển, đèn pha treo).
- Phòng sơn kín có cửa kính quan sát + 4 quạt hút tường + giàn đèn.
- Góc xưởng: máy nén khí, tủ đồ nghề 6 ngăn, 3 lốp xe xếp chồng, thùng dầu, bảng treo dụng cụ.
- Sân: 4 ô đỗ có vạch vàng + gờ chặn bánh, hàng rào lưới B40, cổng sắt 2 cánh mở được.
- Văn phòng nhỏ góc sân: bàn giấy, 2 ghế, tủ hồ sơ, cửa kính.

QA + SUBMIT: y hệt A1, mã C1_LA_MESA_GARAGE.
```

---

## 🅲 C2 — BIỆT THỰ PACIFIC BLUFFS CHI TIẾT (Vòng 2 · chỉ làm SAU khi C1 được duyệt)

```text
<TASK_ID> = C2_PACIFIC_BLUFFS_VILLA
Công trình : Biệt thự ven vịnh "Pacific Bluffs Villa" — 2 tầng + hồ bơi vô cực
Ô đất     : Plot_E1 — X từ -536 đến -358, Z từ -204 đến -60  (178 × 144 stud = 53 × 43 m)
File      : src/shared/World/Modules/Plot_E1_PacificBluffsVilla.luau
PlotId    : "Plot_E1"
Mặt nền   : Y = 1.15 · dựng trực tiếp · ngân sách 2 200 – 3 400 khối, ≥ 95 % máu ẩn.

⚠️ ĐÂY LÀ BẢN DỰNG LẠI. Bản cũ (176 khối, kiểu "ít part") đã bị Chủ dự án GỠ vì nhìn không đẹp.
Yêu cầu lần này: CHI TIẾT từng viên gạch như LS Customs — KHÔNG dùng DestructibleShell để dựng
khối nhà, chỉ dùng nó cho panel kính / tấm vỏ nếu cần.

KIẾN TRÚC BẮT BUỘC:
- Thân nhà 2 tầng chữ L, mỗi tầng 11 stud (3,3 m): tường gạch ghép từng viên, ban công sắt rèn,
  cửa sổ kính chia ô có máu ẩn từng ô, mái ngói đỏ xếp lớp.
- Tầng trệt: sảnh đá, phòng khách có lò sưởi thật (ống khói lên mái), bếp đảo, phòng ăn 8 ghế.
- Tầng 2: 3 phòng ngủ (mỗi phòng có giường, tủ, bàn), 2 phòng tắm (bồn + sen + gương).
- Ngoài: hồ bơi vô cực 26 × 12 stud (3 tầng nước màu), sàn hiên gỗ teak, 4 ghế dài + 2 dù,
  khu BBQ có bếp than, 7 cây cọ + bụi cây, gara 2 xe có cửa cuốn ≥ 15 × 11, hàng rào cây cao.
- Chi tiết: đèn sân 6 cột, chậu cây 8 cái, số nhà "1972" trên cổng, hòm thư, chuông cửa.

QA + SUBMIT: y hệt A1, mã C2_PACIFIC_BLUFFS_VILLA.
```

---

## ❌ BỊ TRẢ BÀI NGAY

| Lỗi | Hậu quả |
| :--- | :--- |
| Tràn khỏi biên ô đất (dù 0.1 stud) | Đè công trình khác → **trả về** |
| Dùng `WorldGrid.RELOCATION` / dựng ở toạ độ cũ | Lệch cả ô → **trả về** |
| Dựng kiểu "ít part" cho cả khối nhà | Sai yêu cầu Chủ dự án → **trả về** |
| < 95 % khối có máu ẩn | Sai linh hồn dự án → **trả về** |
| Sửa file lõi / commit `studio-sync.json` | Xung đột Git → **trả về** |
| Cửa < 8 stud / trần < 14 stud / garage < 15 × 11 | Nhân vật hoặc xe kẹt → **trả về** |
| Không có ảnh render / không có bảng số liệu | Không nghiệm thu được → **trả về** |
| Merge PR của chính mình | Vi phạm quy trình → **trả về** |
