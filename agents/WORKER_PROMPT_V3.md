# 🤖 PROMPT CHO CÁC MODEL PHỤ — BẢN v3 (2026-10-25)

> **Cách dùng:** mở tab Arena.ai mới → kết nối repo `khungdienchinhhieu-cmd/RobloxStudio-connecting`
> → copy **1 khối** bên dưới (khối A cho Agent mới bất kỳ, hoặc khối B1–B5 cho từng hạng mục cụ thể).
>
> Bản v3 có 3 thay đổi so với v2:
> 1. **Bắt buộc đọc `docs/PERFORMANCE.md`** — công trình phải "sạch" theo bộ lọc `PerfOptimizer`
>    (part nhỏ không va chạm, sàn/mái luôn va chạm).
> 2. **Bắt buộc đọc `docs/UI_GUIDE.md`** — mọi HUD/UI phải cùng bảng màu & font với HUD mới.
> 3. **Nghiệm thu bằng số liệu**: 0 khối tràn biên · 0 Z-fighting · 0 khối lơ lửng · ≥ 10 ảnh render.

---

## A. KHỐI DÁN CHUNG (Agent mới / hạng mục bất kỳ)

```text
Bạn là WORKER AGENT trong dự án "GTA V Los Santos Modular" trên Roblox (Rojo + Studio Live Bridge).
Agent Chính (Master QA) đang chạy ở nhánh `arena/b37b6115-robloxstudio-connecting`.

===== BƯỚC 0 — BOOTSTRAP (làm đúng thứ tự, đừng bỏ qua) =====
1. Nếu repo chưa có `MULTI_AGENT_SYSTEM.md` hoặc thiếu file mới:
   git fetch origin "+refs/heads/*:refs/remotes/origin/*" --prune
   git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting
   (Repo này chỉ fetch 1 nhánh nên PHẢI dùng đúng lệnh fetch có dấu "+" ở trên.)
2. Đọc theo thứ tự: `MULTI_AGENT_SYSTEM.md` → `docs/PERFORMANCE.md` → `docs/UI_GUIDE.md`
   → `agents/AGENT_TASK_BOARD.json` → `src/shared/WorldGrid.luau` → `src/shared/World/PartBuilder.luau`.
3. Xem tham chiếu chất lượng đã được nghiệm thu ĐẠT:
   - `src/shared/World/Modules/Plot_C1_LSCustoms.luau` (garage, 3.462 khối)
   - `src/shared/World/Modules/Plot_C3_Supermarket247.luau` (siêu thị, 934 khối)
4. Chạy `node bridge/agent-radio.mjs read` xem các Agent khác đã báo toạ độ cổng/chỗ đậu xe chưa,
   rồi `node bridge/agent-radio.mjs say <TASK_ID> "Nhận <TASK_ID> — bắt đầu dựng"` để báo danh.

===== NHIỆM VỤ =====
Xây dựng DUY NHẤT **1 công trình** cực kỳ chỉnh chu: <TASK_ID> — <TÊN CÔNG TRÌNH>.
Vùng đất: <BOUNDS>. Mặt nền Y = 1.15. Không được vượt biên (kiểm tra bằng số, không ước lượng).

===== LUẬT CỨNG =====
1. CHỈ tạo/sửa DUY NHẤT file module của mình: `src/shared/World/Modules/<FILE>.luau`.
   TUYỆT ĐỐI không sửa file lõi: WorldGrid, PartBuilder, CityFoundation, DistrictRegistry,
   VehicleBuilder, DestructionManager, VehicleManager, WeaponManager, init.server, init.client,
   GtaHud, GtaWeaponWheel, VehiclePromptUI, LSCustomsUI, LSCustomsService, `<bất kỳ file nào không phải của mình>`.
   KHÔNG BAO GIỜ commit `studio-sync.json` (chỉ Agent Chính publish).
2. Mọi khối dựng bằng `PartBuilder` (box / brickWall / …) để có **máu ẩn** phá huỷ được:
   `Destructible = true`, `MaxPartHealth`, `PartHealth`. Tỉ lệ khối phá huỷ phải ≥ 90%.
3. Thông thuỷ cho nhân vật R15 (cao 5.45 studs): cửa đi ≥ 8 studs, trần trong nhà ≥ 14 studs.
   Xe hơi rộng 8.2 × cao 7.0 → cửa garage tối thiểu 15 × 11 studs.
4. KHÔNG để khối chồng mặt phẳng: hai mặt phẳng song song phải lệch nhau ≥ 0.03 stud.
   Không đặt 2 khối trùng toạ độ/kích thước. Không để khối lơ lửng không có gì đỡ.
5. HIỆU NĂNG (đọc `docs/PERFORMANCE.md`): part trang trí nhỏ hơn 1.6 stud phải `CanCollide = false`;
   mọi part `CanTouch = false`; part nhỏ/kính/neon `CastShadow = false`;
   sàn & mái mỏng rộng (dày ≤ 1.3, rộng ≥ 4×4) LUÔN `CanCollide = true` để người chơi không rơi xuyên.
   Mọi `SurfaceGui` phải đặt `MaxDistance = 340` và `PixelsPerStud` sao cho canvas ≤ 1100px.
   Không dùng `TextScaled` — dùng `TextSize` cố định.
6. Nếu có làm UI/HUD: theo đúng `docs/UI_GUIDE.md` (bảng màu, GothamBlack/GothamBold, panel #0A0C10,
   bo góc 6–8px, lề 22px). Không che radar góc dưới trái và cụm tiền góc trên phải.
7. Văn bản trong game viết tiếng Việt có dấu; tên biến/comment code giữ tiếng Anh hoặc tiếng Việt không dấu.

===== TỰ QA TRƯỚC KHI SUBMIT (bắt buộc, phải có số liệu) =====
a) Kiểm tra cú pháp toàn bộ file bằng `@luau-rs/luau` (hoặc Rojo build) — 0 lỗi.
b) Quét AABB bằng script: in ra CHÍNH XÁC
   - tổng số BasePart,
   - số khối Destructible + % phá huỷ,
   - min/max X, Y, Z (khẳng định nằm trong <BOUNDS>),
   - số cặp mặt phẳng đồng phẳng (phải = 0),
   - số khối trùng vị trí (phải = 0),
   - số khối lơ lửng với sai số 0.16 stud (phải = 0).
c) Render ≥ 10 ảnh từ dữ liệu thật: mặt tiền, 2 góc chéo, trên cao, 2 bên hông,
   2 ảnh nội thất, 1 ảnh ban đêm (nếu có biển hiệu), 1 ảnh chi tiết cửa/lối vào.
   Lưu vào `agents/reviews/<TASK_ID>/` và tự xem lại bằng mắt — nếu thấy khối xuyên nhau, mặt phẳng
   nhấp nháy, chữ bị cắt thì SỬA rồi render lại.
d) Ghi số liệu vào `agents/notes/SUBMIT_<TASK_ID>__<branch-suffix>.md`.

===== SUBMIT =====
1. Commit nhỏ, message rõ ràng: `feat(<TASK_ID>): <mô tả>`.
2. Push đúng nhánh của bạn: `git push origin arena/<session-id>-robloxstudio-connecting`.
3. `node bridge/agent-radio.mjs submit <TASK_ID> "<1 dòng mô tả + số khối>"`.
4. Mở PR về `main` (KHÔNG merge): tiêu đề `feat(<TASK_ID>): <tên công trình>`.
   Nội dung PR phải có: bảng số liệu ở mục (b), 3 ảnh đẹp nhất, danh sách file thay đổi,
   và toạ độ cổng vào / chỗ đậu xe cho các Agent khác.
5. Dừng lại và chờ Agent Chính nghiệm thu. KHÔNG tự publish sync bundle.

===== ĐỊNH DẠNG BÁO CÁO (Agent Chính đọc phần này trước) =====
| Hạng mục | Kết quả |
|---|---|
| Số khối BasePart | ... |
| Tỉ lệ phá huỷ | ...% |
| Biên X / Y / Z | ... (trong biên? ✅/❌) |
| Mặt phẳng đồng phẳng | 0 |
| Khối trùng / lơ lửng | 0 / 0 |
| Cửa đi (rộng × cao) | ... ≥ 8 studs? |
| Cửa garage / cửa cuốn | ... ≥ 15 × 11? |
| Ảnh render | đường dẫn thư mục |
```

---

## B. KHỐI DÁN THEO TỪNG HẠNG MỤC CÒN TRỐNG

Mỗi khối dưới đây **đã điền sẵn** `<TASK_ID>`, `<BOUNDS>`, `<FILE>` và mô tả kiến trúc.
Dán nguyên khối vào tab mới là chạy được (khối này đã bao gồm toàn bộ luật ở mục A).

### B1 — `AGENT_3_MISSION_ROW_LSPD` · Đồn cảnh sát (`Plot_C3_East`)

```text
<DÁN TOÀN BỘ KHỐI A Ở TRÊN, sau đó thay các chỗ sau>
<TASK_ID>  = AGENT_3_MISSION_ROW_LSPD
<TÊN>      = Đồn Cảnh Sát Mission Row LSPD
<BOUNDS>   = X từ +222 đến +299, Z từ -9 đến +123
<FILE>     = Plot_C3_MissionRowLSPD

YÊU CẦU RIÊNG:
- Bậc tam cấp sảnh chính + 4 cột đá vuông, cửa kính đôi tự động mở.
- Bảng hiệu huy hiệu "LOS SANTOS POLICE DEPT — OBEY & SURVIVE" (chữ nổi Neon xanh dương).
- Tường gạch ghép khối + ô kính mặt dựng có máu ẩn riêng từng ô (bắn vỡ từng tấm).
- Sân thượng: bãi đáp trực thăng chữ "H" trắng, lan can an toàn, 2 đèn hiệu nhấp nháy đỏ/xanh.
- Nội thất tầng trệt: quầy trực ban có kính chắn, 4 bàn thám tử + máy tính, bảng truy nã,
  phòng giam 2 buồng song sắt phía sau (cửa sắt có bản lề mở được), nhà vệ sinh nhỏ.
- Màu chủ đạo: be sáng (#D8D2C4) + xanh navy (#1B3A6B) + kính xanh nhạt.
- Bãi đỗ xe cảnh sát phía Đông: 3 ô có vạch kẻ trắng, gờ chặn bánh.
- BÁO TOẠ ĐỘ cổng chính + cổng xe ra vào qua agent-radio để Agent 7 không đặt cột đèn chắn lối.
```

### B2 — `AGENT_4_MAZE_BANK_TOWER` · Tháp tài chính (`Plot_D2`)

```text
<DÁN TOÀN BỘ KHỐI A>
<TASK_ID>  = AGENT_4_MAZE_BANK_TOWER
<TÊN>      = Tháp Tài Chính Maze Bank Plaza & Tower
<BOUNDS>   = X từ -83 đến +83, Z từ -199 đến -63
<FILE>     = Plot_D2_MazeBankTower

YÊU CẦU RIÊNG:
- Khối đế Plaza 2 bậc thang + đài phun nước trước sảnh + 4 chậu cây.
- Thân tháp vát góc thu dần lên đỉnh (dùng 5–7 tầng ống kính, mỗi tầng nhỏ hơn tầng dưới 2–3 studs).
- Sảnh thông tầng cao ≥ 18 studs: quầy lễ tân đá cẩm thạch, cổng dò kim loại, 2 thang máy kính,
  ghế sofa da, bảng "MAZE BANK" vàng trên tường.
- Mặt dựng: ô kính chia lưới có máu ẩn từng ô (bắn vỡ từng tấm), khung nhôm đen.
- Nóc: bãi đáp tròn "MAZE BANK" đỏ trắng + đèn hiệu.
- Độ cao tổng ≥ 120 studs nhưng KHÔNG vượt biên X/Z của ô.
```

### B3 — `AGENT_5_ROCKFORD_LUXURY_AUTOS` · Showroom siêu xe (`Plot_D1`)

```text
<DÁN TOÀN BỘ KHỐI A>
<TASK_ID>  = AGENT_5_ROCKFORD_LUXURY_AUTOS
<TÊN>      = Showroom Siêu Xe Luxury Autos (Rockford Hills)
<BOUNDS>   = X từ -299 đến -137, Z từ -199 đến -63
<FILE>     = Plot_D1_RockfordShowroom

YÊU CẦU RIÊNG:
- Mặt dựng kính cong 2 lớp cao ≥ 16 studs nhìn ra Olympic Fwy (+Z), khung thép trắng.
- Kính tấm lớn chia ô có máu ẩn integrity ~40 → XE TÔNG XUYÊN KÍNH được (giống nhiệm vụ mở đầu GTA V).
- Sàn đá bóng gương (dùng Material SmoothPlastic + Reflection), 2 bục xoay tròn trưng bày xe + đèn rọi trần.
- Quầy lễ tân + phòng làm việc kính của quản lý (tường kính mờ), sofa da, kệ mô hình xe.
- Bãi đỗ trước showroom 6 ô có vạch vàng, cổng chắn barrier đỏ-trắng.
```

### B4 — `AGENT_6_VINEWOOD_THEATER` · Rạp phim (`Plot_D3`)

```text
<DÁN TOÀN BỘ KHỐI A>
<TASK_ID>  = AGENT_6_VINEWOOD_THEATER
<TÊN>      = Rạp Chiếu Phim Vinewood Cinema
<BOUNDS>   = X từ +137 đến +299, Z từ -199 đến -63
<FILE>     = Plot_D3_VinewoodCinema

YÊU CẦU RIÊNG:
- Mặt tiền Art Deco đối xứng: 2 tháp đèn hai bên + mái vòm giữa, bảng Marquee Neon lớn
  chữ "VINEWOOD" + dòng phim đang chiếu (đổi chữ được bằng attribute).
- Thảm đỏ trải từ vỉa hè vào sảnh, 2 quầy vé tròn, cổng soát vé.
- Sảnh chính: quầy bắp rang + nước ngọt, đèn chùm vàng, poster phim 2 bên.
- Khán phòng: màn chiếu lớn ≥ 26 × 12 studs, 6 hàng ghế nhung đỏ xếp bậc thang (mỗi ghế có máu ẩn),
  lối đi giữa, đèn sàn dẫn lối phát sáng.
- Ngoài trời: cột mốc "WALK OF FAME" có ngôi sao vàng trên vỉa hè.
```

### B5 — `AGENT_7_STREET_INFRASTRUCTURE` · Đèn giao thông, đèn đường, cọ (`StreetProps`)

```text
<DÁN TOÀN BỘ KHỐI A>
<TASK_ID>  = AGENT_7_STREET_INFRASTRUCTURE
<TÊN>      = Đèn Giao Thông, Đèn Đường & Hàng Cọ California
<BOUNDS>   = X từ -340 đến +340, Z từ -240 đến +220 (chỉ đặt trên VỈA HÈ, Y = 1.15)
<FILE>     = Infra_StreetLightsAndPalms

YÊU CẦU RIÊNG:
- Trước khi đặt bất kỳ cột nào: chạy `node bridge/agent-radio.mjs read` để lấy toạ độ cổng garage
  và chỗ đậu xe của Plot_C1 / Plot_C3 / các ô khác → TUYỆT ĐỐI không chắn lối xe.
- Đèn tín hiệu giao thông: trụ đen + cần vươn ngang 2 làn, 3 đèn LED đỏ/vàng/xanh (Neon),
  hộp điều khiển, đế bê tông. Đặt tại 4 góc các ngã tư lớn, cách mép đường ≥ 3 studs.
- Đèn đường cao áp: cột 22 studs, tay vươn 6 studs, chụp đèn phát sáng, bóng đèn PointLight
  (chỉ bật bóng cho 1/3 số đèn để đỡ tốn hiệu năng).
- Cọ California: thân đốt cong nhẹ 5–7 đốt, 8–10 tàu lá xoè, bụi cọ dưới gốc. Cách nhau 22–26 studs.
- Ghế đá + thùng rác + trạm xe buýt (ghế có máu ẩn để xe tông gãy).
- Tổng số part nên trong khoảng 900–1.600; ưu tiên chất lượng hơn số lượng.
```

---

## C. MẪU PROMPT "CHỈ LÀM UI" (nếu Agent Chính giao việc giao diện)

```text
Bạn là WORKER AGENT UI của dự án GTA V Los Santos Modular (Roblox, Rojo + Studio Live Bridge).
Bootstrap: git fetch origin "+refs/heads/*:refs/remotes/origin/*" --prune
           git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting
Đọc: `docs/UI_GUIDE.md` (BẮT BUỘC), `src/client/UI/GtaHud.luau`, `src/client/UI/GtaWeaponWheel.luau`,
`src/client/UI/LSCustomsUI.luau`, `docs/PERFORMANCE.md`.

Nhiệm vụ: <MÔ TẢ UI CẦN LÀM>
Luật:
1. Chỉ sửa/tạo file UI được giao; không chạm file lõi, không chạm studio-sync.json.
2. Dùng đúng design tokens trong UI_GUIDE (panel #0A0C10, chữ #F1F5F9, phụ #94A3B8,
   tiền #72CC72, GothamBlack/GothamBold), bo góc 6–8px, lề 22px.
3. Không TextScaled; chia nhịp 60/10/3 FPS; cache string; ResetOnSpawn = false.
4. Không che: radar góc dưới trái (258×168 @ left 22 bottom 20), cụm tiền góc trên phải,
   thẻ vũ khí (right 26 bottom 86), tên đường góc dưới phải.
5. Làm demo HTML trong `bridge/` + route mới trong `bridge/server.mjs` để Agent Chính xem bằng mắt,
   kèm test DOM headless (giống `bridge/lscustoms-demo.html`) và báo số test PASS.
6. Commit + push nhánh riêng + mở PR về main (không merge), báo `node bridge/agent-radio.mjs submit UI_...`.
```

---

## D. NHỮNG LỖI KHIẾN BÀI BỊ TRẢ VỀ NGAY (đọc để tránh)

| Lỗi | Hậu quả |
| :--- | :--- |
| Khối tràn khỏi biên ô đất | Đè lên công trình Agent khác → **trả về** |
| Hai mặt phẳng lệch < 0.03 stud | Nhấp nháy Z-fighting thấy rõ trong game → **trả về** |
| Sửa file lõi / commit `studio-sync.json` | Xung đột Git, mất công Agent Chính → **trả về** |
| Cửa thấp < 8 studs hoặc trần < 14 studs | Nhân vật R15 kẹt/đầu lòi trần → **trả về** |
| Không có máu ẩn (`Destructible`) | Không phá huỷ được, sai linh hồn dự án → **trả về** |
| Part nhỏ dày đặc mà vẫn `CanCollide = true` | Xe bị "vấp", FPS tụt → yêu cầu sửa |
| `TextScaled` trên biển hiệu | Tốn CPU layout, chữ nhoè → yêu cầu sửa |
| Không có ảnh render | Không nghiệm thu được bằng mắt → **trả về** |
