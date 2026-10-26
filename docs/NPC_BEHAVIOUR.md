# NPC như người thật — thiết kế & thông số (Sync v24)

> Mục tiêu của Chủ dự án: **“NÂNG CẤP TOÀN BỘ NPC NHƯ NGƯỜI THẬT”** — NPC phải **đông, nhìn thấy,
> đang đi**, mỗi người **một ngoại hình khác nhau**, và khi dừng lại thì **làm việc như người**
> (nghe điện thoại, nói chuyện với nhau, ngắm cảnh, ngắm hàng) chứ không đứng như tượng.

---

## 1. Lỗi gốc đã tìm ra: “thành phố trống, chỉ có 1 NPC”

**Triệu chứng:** chỉ thấy đúng một NPC — mặc skin của chính người chơi — đứng im.
**Thực tế:** đó **không phải NPC đi bộ**, mà là **bản sao của người chơi** (`spawnPlayerTwin`);
**0/84 NPC nền** được dựng và không có một dòng log nào.

Nguyên nhân nằm ở cách nhận giá trị trả về của hàm nhiều kết quả (`v21` → `v23`):

```lua
-- ❌ SAI
local r15 = NPCAppearance.build(arch.id, cf, arch.walkSpeed, arch.health)
if r15 then
    model, hum, hrp, head = r15        -- r15 chỉ là Model; băm theo 1..4 -> nil hết
end
```

`NPCAppearance.build()` trả về **4 giá trị** `(model, humanoid, humanoidRootPart, head)`.
Gán vào **một biến** thì Lua chỉ giữ giá trị **đầu tiên**. Bước sau băm `Model` theo chỉ số
`1..4` nên `hum`, `hrp`, `head` đều `nil` → dòng kế tiếp `patrolTarget = hrp.Position` **nổ** →
`spawnAmbient` gọi trong `pcall` nên **nuốt lỗi im lặng** → dân số = 0.

`spawnPlayerTwin` dính **y hệt** (`local built = NPCAppearance.fromPlayer(...)` rồi băm `built`),
nên đường “bản sao người chơi” cũng chết — và nếu có ai đó thấy một NPC giống hệt mình thì đó là
tàn dư của đường này ở phiên bản trước.

**Sửa ở v24:** nhận đủ 4 giá trị ở cả 3 chỗ — `NPCManager.spawn`, `NPCManager.spawnPlayerTwin`,
`NPCAppearance.fromPlayer`. Không đổi logic nào khác.

**Bằng chứng:** `tools/npc_sim/run.cjs` (harness chạy thật `NPCManager.luau` bằng Luau WASM):

```
getStats: sống=93 r15=93 xe=8
[NPC diagnose] sống=93 · điểm vỉa hè=267 · jogger=3
                hoạt động: IDLE=4, LOOK=11, PHONE=8, TALK=10, WALKING=55, WINDOW=5
di chuyển trong 60s: 84/93 NPC đi > 8 stud (xa nhất 557)
số cảnh báo: 0
```

`93 = 84 đi bộ + 1 bản sao + 8 tài xế`. 8 NPC “không đi” là tài xế (đúng thiết kế).

---

## 2. Ngoại hình: người thật thì ai cũng một khác

Mỗi NPC khi dựng xong được random hoá (R15 dùng các thuộc tính `Body*Scale` của `Humanoid`):

| Thuộc tính | Khoảng | Ý nghĩa |
|---|---|---|
| `BodyHeightScale` | `0,90 – 1,10` | người thấp / cao |
| `BodyWidthScale` | `0,92 – 1,08` | gầy / đậm |
| `BodyDepthScale` | `0,95 – 1,05` × width | bề dày |
| `BodyTypeScale` | `0,92 – 1,08` | dáng người |
| `HeadScale` | `0,94 – 1,06` | đầu to / nhỏ |

Cộng với bảng sơn có sẵn của `NPCAppearance` (7 tông da × 9 màu áo × 5 màu quần × 4 màu giày)
→ gần như không có hai NPC nào giống nhau.

**Jogger:** du khách 10 %, dân thường 8 % được gắn `jog = true` → `WalkSpeed = max(18, walk + 6)`
và chạy bằng animation `RUN` thay vì `WALK`.

---

## 3. Hoạt động đời thường (section 9.6 trong `NPCManager.luau`)

NPC không còn “dừng 2–6 giây rồi đi tiếp”. Mỗi lần **tới đích**, nó bốc một hoạt động theo
**trọng số riêng của loại người**, rồi mới đi tiếp.

| Hoạt động | Thời lượng | Cách làm |
|---|---|---|
| 🧍 `IDLE` | 2–6 s | đứng thở, nhìn quanh |
| 📞 `PHONE` | 6–14 s | **rút điện thoại thật** (part `Phone` + `PhoneScreen` hàn vào `RightHand`), giơ lên tai, gật gù |
| 💬 `TALK` | 7–15 s | tìm NPC khác trong **18 stud**; **cả hai quay mặt vào nhau**, người kia cũng được gắn `TALK` |
| 👀 `LOOK` | 3–7 s | dõi theo **người chơi** gần nhất trong **34 stud**; không có ai thì ngó quanh phố |
| 🛍️ `WINDOW` | 4–9 s | quay mặt ra mặt đường, đứng ngắm hàng |

**Trọng số theo archetype** (`ROUTINE_WEIGHTS`):

| | IDLE | PHONE | TALK | LOOK | WINDOW |
|---|---|---|---|---|---|
| CIVILIAN | 3 | 4 | 3 | 2 | 2 |
| BUSINESS | 2 | **6** | 3 | 1 | 1 |
| TOURIST | 3 | 1 | 2 | **5** | 2 |
| GANGSTER | 3 | 2 | **4** | 2 | **0** |
| BRAWLER | 3 | 1 | 3 | 2 | **0** |
| COP | 4 | 1 | 1 | **5** | **0** |
| THUG | 3 | 1 | 3 | 2 | **0** |

Điều kiện thực tế: `PHONE` chỉ dùng cho archetype có `hasPhone = true`; `TALK` mà **không có ai
gần** thì tự chuyển thành `LOOK`; `LOOK` mà không có người chơi gần thì **vẫn ngắm cảnh**
(quay về một điểm ngẫu nhiên), **không hoá đá**.

---

## 4. Không bao giờ trống thành phố (bảo hiểm 4 lớp)

1. **`findGround` có phương án hình học** — trong thành phố (`|X| ≤ MAP_HALF_SIZE`, `Z −250..200`)
   luôn trả `Y = SIDEWALK_TOP_Y` (1,15) kể cả khi tia chiếu trượt, nên việc thả NPC không phụ thuộc
   raycast (part nền `CanQuery = false` / thành phố chưa dựng xong).
2. **Mỗi NPC dựng trong `pcall` + đếm lỗi** (`spawnErrors`) và cảnh báo 3 lần đầu → lần sau lỗi
   không còn im lặng nữa.
3. **Vòng cứu hộ 16 NPC** quanh `WorldGrid.SPAWN_POS` nếu `spawnAmbient` vẫn ra 0.
4. **Thử lại sau 6 s và 15 s** nếu dân số < 20; nếu vẫn 0 thì log chỉ đúng câu lệnh chẩn đoán.

**Chẩn đoán trong Studio** (Command Bar):

```lua
print(require(game.ServerScriptService.Server.NPCManager).diagnose())
```

In ra: số NPC sống · số điểm vỉa hè · số jogger · **biểu đồ hoạt động** · tỉ lệ tia chiếu trượt.

---

## 5. Kiểm tra bằng mắt trước khi mở Studio

`bridge/city-life-demo.html` (route `/city` của bridge) mô phỏng **đúng luật** trên:
mỗi NPC có chiều cao riêng, jogger chạy nhanh hơn, **vòng màu + emoji** cho hoạt động đang làm,
và bảng đếm riêng 📞 / 💬 / 👀 / 🛍️ / 🧍.
