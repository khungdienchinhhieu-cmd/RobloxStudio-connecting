# 🎯 PROMPT CHO AGENT PHỤ — CHUYÊN UI/UX + MODEL SÚNG (bản v4 · 2026-10-26)

> **Dùng khi nào:** bạn cần một Agent phụ **chỉ** làm giao diện và mô hình vũ khí, không đụng
> tới quy hoạch thành phố / công trình / NPC / xe.
>
> **Cách dùng:** mở tab Arena.ai mới → kết nối repo `khungdienchinhhieu-cmd/RobloxStudio-connecting`
> → dán **KHỐI 0** (bắt buộc) → rồi dán **một** trong các thẻ việc `W1…W6`.
>
> Bản v4 khác v3 ở 4 điểm:
> 1. **Khoá phạm vi (scope lock)** — chỉ được sửa file UI + vũ khí, danh sách cấm ghi rõ từng file.
> 2. **Tỉ lệ 1:1 ngoài đời** — mọi kích thước (kể cả súng) phải quy đổi qua `WorldGrid.meters()`.
> 3. **Bắt buộc có demo HTML** trong `bridge/` để Agent Chính xem bằng mắt trước khi nghiệm thu.
> 4. **Bắt buộc có bảng số liệu QA** (part, độ trễ, vùng che) — không chấm bằng cảm tính.

---

## KHỐI 0 — DÁN CHUNG (bắt buộc, dán trước thẻ việc)

```text
Bạn là WORKER AGENT chuyên UI/UX + MODEL VŨ KHÍ của dự án "GTA V Los Santos Modular" trên Roblox
(Rojo + Studio Live Bridge). Agent Chính (Master QA) chạy ở nhánh
`arena/b37b6115-robloxstudio-connecting`.

===== BƯỚC 0 — BOOTSTRAP (làm đúng thứ tự) =====
1. Nếu repo chưa có file mới hoặc thiếu `agents/WORKER_PROMPT_V4_UI_WEAPONS.md`:
   git fetch origin "+refs/heads/*:refs/remotes/origin/*" --prune
   git merge --no-edit origin/arena/b37b6115-robloxstudio-connecting
   (Repo này chỉ fetch 1 nhánh nên PHẢI dùng đúng lệnh fetch có dấu "+" ở trên.)
2. Đọc theo thứ tự, ĐỪNG bỏ qua:
   a) `docs/UI_GUIDE.md`            — bảng màu, font, bo góc, vùng màn hình bị khoá
   b) `docs/PERFORMANCE.md`         — luật hiệu năng (TextScaled, RenderStepped, part nhỏ)
   c) `agents/AGENT_TASK_BOARD.json` — mục `uiContract` + `zeroConflictContract`
   d) `src/client/UI/GtaHud.luau`, `src/client/UI/GtaWeaponWheel.luau`,
      `src/client/WeaponClient.luau`, `src/server/WeaponManager.luau`
   e) `src/shared/WorldGrid.luau`   — CHỈ ĐỌC, để lấy `WorldGrid.meters()` và `STUDS_PER_METER`
3. Chạy `node bridge/agent-radio.mjs read` để xem Agent khác đang giữ khu vực nào,
   rồi `node bridge/agent-radio.mjs say <TASK_ID> "Nhận <TASK_ID> — bắt đầu"`.

===== TỈ LỆ 1:1 (bắt buộc, từ Sync v22) =====
Dự án dùng **1 m = 3,33 stud** (`WorldGrid.STUDS_PER_METER`). KHÔNG đặt số stud tuỳ hứng.
Mọi kích thước phải viết dưới dạng `WorldGrid.meters(<số mét>)` hoặc kèm comment `-- x m`.
Bảng đối chiếu ngoài đời (đã nhân 3,33; đây là chuẩn để bạn bám theo):

| Vật thể | Ngoài đời | Stud (1:1) |
| :--- | ---: | ---: |
| Nhân vật R15 | 1,65 m | 5,0 |
| Glock 17 (Pistol 9mm) | 0,20 m | 0,67 |
| Glock 18 (AP Pistol) | 0,19 m | 0,63 |
| Micro SMG (Uzi, báng gập) | 0,47 m | 1,57 |
| M4 (Carbine Rifle) | 0,84 m | 2,80 |
| Assault Shotgun | 0,98 m | 3,27 |
| Sniper (Heavy Sniper) | 1,40 m | 4,66 |
| RPG-7 | 0,95 m | 3,17 |
| Gậy bóng chày | 0,86 m | 2,87 |
| Điện thoại (iFruit) | 0,15 m | 0,50 |

**Sàn dễ đọc (readability floor):** ở khoảng cách 20 stud, chiều nhỏ nhất của **silhouette**
không được dưới **0,30 stud** và tay cầm (grip/handle) luôn ≥ **0,55 stud** để bàn tay R15
(`RightHand`) cầm chắc. Nếu phải vượt quá +10 % so với bảng trên để dễ đọc, ghi rõ lý do vào báo cáo.

===== LUẬT CỨNG (vi phạm = trả bài ngay) =====
1. **SCOPE LOCK — chỉ được tạo/sửa các file sau:**
   - `src/client/UI/*.luau` (mọi file UI, kể cả tạo mới)
   - `src/client/WeaponClient.luau`
   - `src/shared/Weapons/**` (thư mục mới, tuỳ bạn tổ chức)
   - `bridge/<ten>-demo.html` (tạo mới) + **thêm đúng 1 route** trong `bridge/server.mjs`
   - `agents/notes/SUBMIT_<TASK_ID>__*.md`, `agents/reviews/<TASK_ID>/*`
   - **NGOẠI LỆ DUY NHẤT:** được thay **đúng khối `local GUN_MODELS: { [string]: any } = { … }`**
     trong `src/server/WeaponManager.luau` bằng 2 dòng require factory của bạn. Không sửa bất kỳ
     dòng nào khác trong file đó. Phải chạy lại test để chứng minh đạn/cooldown không đổi.
2. **TUYỆT ĐỐI KHÔNG** đụng: `WorldGrid.luau`, `src/shared/World/**` (PartBuilder, CityFoundation,
   DistrictRegistry, DestructibleShell, Modules/*), `src/server/{NPCManager,NPCAppearance,
   VehicleManager,LSCustomsService,DestructionManager,init.server}.luau`,
   `src/shared/Vehicles/**`, `src/client/NPCAnimator.luau`, `src/client/init.client.luau`,
   `default.project.json`, **`studio-sync.json`** (chỉ Agent Chính publish).
3. **Đồng bộ token UI:** panel `#0A0C10` · panel sáng `#12171F` · viền `#26303F` · chữ `#F1F5F9` ·
   chữ phụ `#94A3B8` · tiền `#72CC72` · máu `#56BA56` · giáp `#3B9BE8` · thể lực `#EEC135` ·
   vàng khu vực `#F0C642`. Font `GothamBlack/GothamBold/GothamMedium`. Bo góc 6–8 px, lề 22 px.
4. **Không che 4 vùng khoá** (`agents/AGENT_TASK_BOARD.json → uiContract.reservedScreenAreas`):
   radar góc dưới trái (left 22, bottom 20, 258×168) · cụm tiền góc trên phải (right 26, top 16,
   292×110) · thẻ vũ khí (right 26, bottom 86, 252×76) · tên đường (right 26, bottom 22).
5. **Hiệu năng:** KHÔNG `TextScaled` (dùng `TextSize` cố định hoặc `AutomaticSize`) · KHÔNG tạo
   Instance trong `RenderStepped`/`Heartbeat` (tạo 1 lần, sau đó chỉ đổi `.Text`/`.Size`/`.Visible`) ·
   cache chuỗi bằng biến, không nối chuỗi mỗi frame · mọi `ScreenGui.ResetOnSpawn = false` ·
   ẩn/hiện bằng `.Visible`, không `Destroy()` rồi dựng lại · ảnh/emoji dùng `rbxassetid` có sẵn,
   không tải nội dung ngoài.
6. **Súng:** mỗi khẩu 8–18 `BasePart`, `CanCollide = false`, `CanTouch = false`, `Massless = true`,
   part mỏng (< 0.6 stud) `CastShadow = false`. Có `Muzzle` (điểm đầu nòng, dùng cho flash + tracer),
   `EjectPort` (điểm hắt vỏ đạn), `Grip`/`Handle` (khớp bàn tay R15). Màu: kim loại `Metal` xám than,
   polymer `SmoothPlastic` đen nhám, gỗ `Wood`. Không dùng `SpecialMesh` bên ngoài `rbxassetid` có sẵn.
7. **Hợp đồng dữ liệu súng phải giữ nguyên** để `WeaponManager.buildWeaponTool()` chạy được:
   mỗi khẩu trả về `{ handle = { size = Vector3, color = Color3 }, parts = { { name, size, off, color } … } }`
   với `off` là offset so với Handle. Tên khẩu phải khớp **đúng 9 tên** đang có:
   `Unarmed`, `Baseball Bat`, `Pistol 9mm`, `AP Pistol`, `Micro SMG`, `Carbine Rifle`,
   `Assault Shotgun`, `Sniper Rifle`, `RPG`.
8. Tiếng Việt có dấu trong mọi chuỗi hiển thị cho người chơi; tên biến/comment code tiếng Anh
   hoặc tiếng Việt không dấu. Không emoji trong UI in-game (chỉ dùng ở tài liệu).

===== TỰ QA TRƯỚC KHI SUBMIT (phải có SỐ LIỆU, không cảm tính) =====
a) **Cú pháp:** biên dịch 100 % file `.luau` bằng `@luau-rs/luau` (hoặc `rojo build`) — 0 lỗi.
   Nếu máy chưa có: `mkdir -p /tmp/luau-check && cd /tmp/luau-check && npm init -y && npm i @luau-rs/luau`
   (thư viện ESM: `const { Lua } = require(...)`, `await Lua.create()`, `lua.compile(src,{chunkName})`).
b) **Đo part:** in ra chính xác tổng `BasePart`, số part mỗi khẩu, tổng độ dài từng khẩu (stud + mét),
   và khẳng định không part nào > 1,15 × chiều dài thật.
c) **Đo UI:** in bảng **mọi** `ScreenGui`/`Frame` cấp cao: `Name`, `AnchorPoint`, `Position`, `Size`,
   và khẳng định **0 vùng giao nhau** với 4 vùng khoá ở mục 4.
d) **Demo HTML:** tạo `bridge/<ten>-demo.html` render đúng dữ liệu thật (mock bằng JS y hệt số liệu
   Luau) + 1 route mới trong `bridge/server.mjs` để Agent Chính mở bằng trình duyệt.
   `node --check bridge/server.mjs` phải PASS. Ảnh chụp/khung hình phải cho thấy UI thật.
e) **Đếm test:** viết test DOM headless (như `bridge/lscustoms-demo.html` đang làm) và ghi
   `PASS/FAIL` từng test. Không có test = trả bài.

===== SUBMIT =====
1. Commit nhỏ, message: `feat(<TASK_ID>): <mô tả ngắn>`.
2. Push **đúng nhánh của bạn**: `git push origin arena/<session-id>-robloxstudio-connecting`.
3. `node bridge/agent-radio.mjs submit <TASK_ID> "<1 dòng + số part + số test PASS>"`.
4. Mở PR về `main` (**KHÔNG merge**): tiêu đề `feat(<TASK_ID>): <tên>`. Nội dung PR phải có:
   bảng số liệu (a–e), đường dẫn demo HTML, danh sách file thay đổi, và **ảnh trước/sau**.
5. Dừng và chờ Agent Chính nghiệm thu. **KHÔNG tự publish sync bundle.**

===== BÁO CÁO (Agent Chính đọc phần này trước) =====
| Hạng mục | Kết quả |
|---|---|
| File đã sửa / tạo | … |
| Có sửa file ngoài scope? | không / có (giải thích) |
| Tổng BasePart mới | … |
| Súng: số part mỗi khẩu · độ dài (stud / mét) | … |
| Vùng UI giao với vùng khoá | 0 |
| Test DOM headless | … PASS / … FAIL |
| Demo | `bridge/<ten>-demo.html` → route `/…` |
| Ảnh / khung hình | `agents/reviews/<TASK_ID>/` |
```

---

## W1 — XƯƠNG SỐNG: `GunModelFactory` (model súng 1:1, 9 khẩu)

```text
<DÁN KHỐI 0>
<TASK_ID> = UI_W1_GUN_MODEL_FACTORY

MỤC TIÊU: thay 9 mô hình súng "khối hộp thô" hiện tại (Pistol dài 1,12 stud = 0,34 m — to gấp đôi
ngoài đời) bằng mô hình dựng từ dữ liệu, đúng tỉ lệ 1:1, đủ chi tiết để nhìn ở góc thứ ba.

TẠO MỚI: `src/shared/Weapons/GunModelFactory.luau`
  - `GunModelFactory.get(weaponName) -> { handle = {...}, parts = {...} }`   (hợp đồng cũ, giữ nguyên)
  - `GunModelFactory.legacySpecs() -> { [string]: any }`  — trả nguyên bảng để WeaponManager dùng
  - `GunModelFactory.dimensions(weaponName) -> { lengthStuds, lengthMeters, partCount }`
  - Dữ liệu khai báo theo MÉT rồi nhân `WorldGrid.STUDS_PER_METER` (không viết số stud tay).

YÊU CẦU TỪNG KHẨU (chi tiết tối thiểu):
  · Pistol 9mm  — thân trượt (slide) có rãnh khía sau, nòng lồi, kim điểm hoả, chốt băng ở đuôi,
                   điểm ruồi trước + hậu, ốp báng có vân. 9–11 part.
  · AP Pistol   — như trên + băng dài thò ra, đầu nòng ren, cò rộng. 10–12 part.
  · Micro SMG   — thân hộp, báng gập kim loại, băng dài cắm trước cò, nòng ngắn có ốp, tay nắm trước. 12–14 part.
  · Carbine Rifle — upper/lower receiver tách rời, ray Picatinny có 6–8 khe, ốp nòng có lỗ thông hơi,
                  báng trượt, ống dẫn khí, tay cầm nghiêng, kính ngắm nhỏ (thấu kính riêng). 14–18 part.
  · Assault Shotgun — receiver vuông, nòng dày, ống chứa đạn dưới nòng, pump có rãnh, báng gỗ. 12–15 part.
  · Sniper Rifle — nòng rất dài có phanh đầu nòng, thân ốp, ống ngắm to (thân · 2 thấu kính · 2 nắp),
                  băng ngắn, chân chống 2 chân gập, báng có tựa má. 14–18 part.
  · RPG          — ống phóng dài, loa phía sau, đầu đạn hình nón 2 tầng, tay cầm trước/sau, kính ngắm bên. 12–16 part.
  · Baseball Bat — thân thuôn dần (dùng 4–5 khối chồng, mỗi khối nhỏ dần), cổ tay cầm quấn băng, nắp chuôi. 6–8 part.
  · Unarmed      — KHÔNG có model (giữ nguyên hành vi cũ).

CHI TIẾT BẮT BUỘC:
  - Mỗi khẩu có part tên đúng: `Handle`, `Muzzle` (đầu nòng), `EjectPort` (hắt vỏ đạn),
    ngoài ra đặt tên có nghĩa (`Slide`, `Receiver`, `Mag`, `Stock`, `Optic`…).
  - `Muzzle` nằm CHÍNH XÁC ở mặt trước đầu nòng (dùng cho flash + tracer sau này) — ghi toạ độ vào báo cáo.
  - Màu sắc: kim loại `Color3.fromRGB(34,36,42)`, thép sáng `(92,96,104)`, polymer `(22,24,28)`,
    gỗ `(120,84,46)`, đồng `(184,140,72)`, kính ngắm `(120,200,230)`.
  - Không part nào lơ lửng: mọi part phải chạm/khớp part khác (sai số 0,02 stud).

KIỂM CHỨNG: sửa đúng khối `GUN_MODELS` trong `WeaponManager.luau` (NGOẠI LỆ ở luật 1) thành
  `local GunModelFactory = require(ReplicatedStorage.Shared.Weapons.GunModelFactory)`
  `local GUN_MODELS = GunModelFactory.legacySpecs()`
  → verify 9 Tool vẫn được tạo, đạn/cooldown/giật không đổi (in bảng spec trước/sau).
```

---

## W2 — HUD 2.0: radar thật + chỉ số GTA V

```text
<DÁN KHỐI 0>
<TASK_ID> = UI_W2_HUD_RADAR

MỤC TIÊU: nâng HUD hiện tại thành HUD GTA V "đọc được trong 0,5 giây".

1. Radar góc dưới trái (giữ đúng vùng 258×168): vẽ bản đồ thật từ toạ độ — đường (9 đại lộ),
   ô đất, bãi biển, đồi; xoay theo hướng camera; blip NPC/xe/lực lượng theo `Attribute`;
   viền bo góc + kim Bắc + tên đường đang đứng.
2. 3 thanh Máu / Giáp / Thể lực: hiện đại hơn, có animation giảm mượt (Lerp theo `dt`), đổi màu
   khi < 30 %, nhấp nháy đỏ khi < 15 %.
3. Cụm tiền (right 26, top 16, 292×110): số tiền chạy từ số cũ → số mới trong 0,6 s, dấu `$` xanh,
   dòng phụ "LOS SANTOS · <khu vực>".
4. Feed sự kiện (trên radar): tối đa 4 dòng, tự mờ dần sau 6 s, icon trái theo loại
   (tiền / máu / truy nã / nhiệm vụ).
5. Thanh truy nã 5 sao: hiện khi `WantedLevel > 0`, nhấp nháy khi cảnh sát đang đuổi.
6. Menu `H` (đã có): giữ nguyên hành vi mở/đóng, chỉ làm đẹp + thêm tab "Cài đặt" có 2 tuỳ chọn
   thật (ẩn/hiện radar · bật/tắt feed).

KHÔNG được che 4 vùng khoá. Demo: `bridge/hud2-demo.html` + route `/hud2`.
```

---

## W3 — Vòng chọn súng + thẻ vũ khí

```text
<DÁN KHỐI 0>
<TASK_ID> = UI_W3_WEAPON_WHEEL_V2

MỤC TIÊU: vòng chọn súng hiện tại (9 ô) đẹp và "đã tay" hơn, không đổi phím tắt.

1. Vòng 9 ô: mỗi ô có **hình bóng (silhouette) vẽ bằng Frame** của đúng khẩu đó (không dùng ảnh ngoài),
   tên tiếng Việt, số đạn `mag / reserve`, viền accent theo loại (bảng accent trong `docs/UI_GUIDE.md`).
2. Ô đang chọn: phóng 1,18×, viền sáng, nền mờ dần; ô bị khoá (hết đạn) mờ 45 % + gạch chéo.
3. Giữ `TAB` mở, chọn theo hướng chuột (giữ nguyên dead-zone 54 px, bán kính 196, ô 108 — Agent Chính
   đã nghiệm thu), thả để trang bị; phím `1–9` đổi nhanh; `R` nạp đạn (đã có).
4. Thẻ vũ khí góc dưới phải (right 26, bottom 86, 252×76): tên + bóng khẩu + `mag/reserve`,
   thanh tiến trình mờ hiện khi đang nạp.
5. Âm thanh UI: chỉ dùng `rbxassetid` có sẵn, âm lượng ≤ 0,35; có công tắc tắt.

Demo: `bridge/weapon-wheel2-demo.html` + route `/weapon-wheel2`.
```

---

## W4 — Màn hình chọn trang bị / kho đồ (Inventory)

```text
<DÁN KHỐI 0>
<TASK_ID> = UI_W4_INVENTORY

MỤC TIÊU: lần đầu có màn hình quản lý vũ khí kiểu GTA V (mở bằng `TAB` giữ 0,6 s hoặc phím `I`).

1. Lưới 4×3 ô vũ khí + cột phải "Chi tiết": bóng khẩu lớn, thông số (sát thương · tốc độ bắn ·
   tầm · băng đạn), thanh so sánh với khẩu đang cầm.
2. Chuột phải = ghim vào vòng chọn nhanh; chuột trái = trang bị ngay; phím `ESC` đóng.
3. Dữ liệu lấy từ RemoteEvent `WeaponSync` sẵn có — KHÔNG tự tạo remote mới, KHÔNG sửa WeaponManager
   (ngoài ngoại lệ W1).
4. Nền làm mờ cảnh (blur + vignette), mở/đóng có animation 0,18 s.

Demo: `bridge/inventory-demo.html` + route `/inventory`.
```

---

## W5 — Hiệu ứng bắn & va chạm (client, không đổi gameplay)

```text
<DÁN KHỐI 0>
<TASK_ID> = UI_W5_COMBAT_FX

MỤC TIÊU: bắn "đã" hơn mà server không phải làm gì thêm.

1. Reticle động: 4 vạch giãn ra khi bắn / chạy, co lại khi đứng yên; đổi màu khi trúng đích (hitmarker
   trắng) và khi hạ gục (đỏ).
2. Muzzle flash tại part `Muzzle` của khẩu đang cầm: 2 part phát sáng + 1 `PointLight` bật 0,05 s.
3. Tracer: 1 part mảnh `Trail` từ `Muzzle` → điểm trúng, sống 0,06 s.
4. Hắt vỏ đạn tại `EjectPort`: 1 part nhỏ `Debris` 0,8 s, có trọng lực nhẹ.
5. Rung camera (camera shake) theo `spec.damage`, giảm dần trong 0,15 s — tắt được trong Cài đặt.
6. Giật súng (recoil) chỉ ở client: khẩu lùi 0,08 stud rồi trả về trong 0,1 s.

Ràng buộc: TẤT CẢ hệu ứng dùng pooling (tạo trước 24 part ẩn, tái sử dụng), **0 allocation** trong
RenderStepped. Demo: `bridge/combat-fx-demo.html` + route `/combat-fx`.
```

---

## W6 — Điện thoại iFruit + bảng chọn nhanh

```text
<DÁN KHỐI 0>
<TASK_ID> = UI_W6_PHONE

MỤC TIÊU: chiếc điện thoại trong game (mở bằng phím `P`), phong cách iFruit của GTA V.

1. Khung máy 0,15 m (0,5 stud) hiển thị như một phần HUD ở góc dưới phải — KHÔNG che 4 vùng khoá.
2. 4 app có chức năng thật: `Danh bạ` (gọi NPC — chỉ hiện thông báo), `Tin nhắn` (log sự kiện),
   `Bản đồ` (mở radar toàn màn hình tạm thời), `Cài đặt` (âm lượng, rung camera, ngôn ngữ).
3. Ảnh app vẽ bằng Frame + TextLabel, không tải ảnh ngoài.
4. Mở/đóng animation trượt 0,2 s; `ESC` đóng; `P` bật/tắt.

Demo: `bridge/phone-demo.html` + route `/phone`.
```

---

## ❌ BẢNG LỖI BỊ TRẢ BÀI NGAY

| Lỗi | Hậu quả |
| :--- | :--- |
| Sửa file ngoài scope (WorldGrid, World/**, NPC*, Vehicle*, studio-sync.json) | Xung đột với Agent Chính → **trả về** |
| Đổi tên 9 khẩu hoặc đổi shape `GUN_MODELS` | `WeaponManager` gãy, mất đạn/cooldown → **trả về** |
| Súng to gấp đôi ngoài đời hoặc nhỏ hơn sàn dễ đọc | Sai tỉ lệ 1:1 → yêu cầu làm lại |
| Che radar / cụm tiền / thẻ vũ khí / tên đường | Không chơi được → **trả về** |
| `TextScaled`, tạo Instance mỗi frame, nối chuỗi mỗi frame | Tụt FPS → **trả về** |
| Không có demo HTML + route | Không nghiệm thu bằng mắt được → **trả về** |
| Không có bảng số liệu QA | Không chấm được → **trả về** |
| Tự `git push` lên nhánh Agent Chính hoặc commit `studio-sync.json` | Phá bundle sync → **trả về** |
| Merge PR của chính mình | Vi phạm quy trình → **trả về** |
