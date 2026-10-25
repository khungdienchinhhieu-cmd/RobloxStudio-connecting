# ⚡ TỐI ƯU HIỆU NĂNG (GIẢM LAG) — Los Santos Modular

> Tài liệu này ghi lại **nghiên cứu** + **số liệu đo thật** + **cách áp dụng** lớp tối ưu
> `src/shared/World/PerfOptimizer.luau`. Mọi thay đổi đều đã kiểm định bằng Luau VM
> trên đúng scene 8.105 part hiện tại.

---

## 1. Nguồn nghiên cứu (tài liệu chính thức Roblox)

| Nguồn | Kết luận dùng để tối ưu |
| :--- | :--- |
| [Improve performance](https://create.roblox.com/docs/performance-optimization/improve) | Part **không cần va chạm** → đặt `CanCollide`, `CanTouch`, `CanQuery` = `false`. Instance streaming là **cách hiệu quả nhất** với thế giới lớn. |
| [Instance streaming – Techniques](https://create.roblox.com/docs/workspace/streaming/techniques) | Khuyến nghị: `StreamingMinRadius = 64`, `StreamingTargetRadius = 1024`, `StreamingIntegrityMode = PauseOutsideLoadedArea`, `ModelStreamingBehavior = Improved`, `StreamOutBehavior = Opportunistic`. |
| [Collisions](https://create.roblox.com/docs/workspace/collisions) | `CanTouch = false` để không sinh `TouchTransmitter` (không dùng `.Touched`). |
| [New SurfaceGui.MaxDistance](https://devforum.roblox.com/t/new-surfaceguimaxdistance-property/2574715) | SurfaceGui cũ mặc định `MaxDistance = 0` = **vẽ ở mọi khoảng cách** → phải đặt giới hạn. |
| [All About Text – Best Practices](https://devforum.roblox.com/t/all-about-text-best-practices/1515743) | `TextScaled` tốn **~10×** thời gian layout. Biển lớn nên hạ `PixelsPerStud` thay vì tăng `TextSize`. |
| [Design for performance](https://create.roblox.com/docs/performance-optimization/design) | Ngân sách thiết bị yếu: **< 1.000 draw call** và **< 1.000.000 triangle**. |
| [Fluid forces](https://devforum.roblox.com/t/turning-off-enablefluidforces-and-cantouch-minimizing-customphysicalproperties/3739234) | `EnableFluidForces` tốn CPU trên part không neo → tắt hết. |

---

## 2. Số liệu ĐO THẬT (trước → sau khi chạy `PerfOptimizer`)

Scene hiện tại: **CityFoundation + Plot_C1 (LS Customs) + Plot_C3_Supermarket247 + 6 xe**.

| Chỉ số | Trước | Sau | Giảm |
| :--- | ---: | ---: | ---: |
| Tổng BasePart (thế giới) | 7.191 | 7.191 | — |
| `CanCollide = true` | 4.359 | **2.975** | **−31,7 %** |
| `CanTouch = true` (sinh TouchTransmitter) | 7.191 | **0** | **−100 %** |
| `CanQuery = true` | 7.187 | 7.024 | −163 |
| `CastShadow = true` (shadow map) | 4.670 | **3.769** | **−19,3 %** |
| Attribute mỗi part phá huỷ | 7 | **5** | **−11.392 attribute** toàn map |
| SurfaceGui chưa giới hạn khoảng cách | 36 | **0** | −100 % |

**Kiểm tra an toàn (không phá gameplay):**

| Hạng mục | Kết quả |
| :--- | :--- |
| Cầu thang còn va chạm | ✅ 16/16 |
| Mặt gác lửng (`MezzDeck*`) | ✅ 4/4 |
| Sàn / máng / tấm đáy | ✅ 57/57 |
| Tường gạch ghép khối | ✅ 1.447 khối |
| Part phá huỷ vẫn bắn vỡ được (`CanQuery`) | ✅ 100 % |

---

## 3. 5 quy tắc `PerfOptimizer` áp dụng

1. **`CanTouch = false` toàn bộ** — dự án không dùng sự kiện `.Touched` (xe tông dùng
   `GetPartBoundsInBox`, súng dùng `Raycast`). Bỏ hẳn `TouchTransmitter` cho ~7.200 part.
2. **Khối trang trí nhỏ, không phá huỷ** (`maxDim < 3`) → tắt cả 3 cờ va chạm.
3. **Khối phá huỷ**: luôn giữ `CanQuery = true` (đạn + quét va chạm xe);
   tắt `CanCollide` khi:
   - cực nhỏ (`maxDim < 1,6`): chữ nổi, viền kính, ốc vít, hộp hàng;
   - là vật phẩm trên kệ (`maxDim < 2,6` và đáy `> 3,2` stud);
   - treo cao (`đáy > 8` stud) và không phải khối kết cấu lớn.
   → **Sàn/mái đi được luôn giữ va chạm** (`dày ≤ 1,3` + rộng `≥ 4×4`) nên không rơi xuyên.
4. **`CastShadow = false`** cho part `maxDim < 2,6`, part trong suốt (kính) và Neon.
5. **`EnableFluidForces = false`** toàn bộ + **SurfaceGui**: `MaxDistance = 340`,
   hạ `PixelsPerStud` để canvas ≤ 1.100 px (biển `24/7` 46 stud: 1.840 px → 1.100 px,
   giảm 64 % diện tích texture).

Ngoài ra gộp **7 → 5 attribute**: bỏ `MaxIntegrity` / `Integrity` (luôn trùng
`MaxPartHealth` / `PartHealth`; `DestructionManager` vẫn đọc fallback nên tương thích).

---

## 4. Tối ưu vòng lặp mỗi frame (script)

| File | Trước | Sau |
| :--- | :--- | :--- |
| `src/client/UI/GtaHud.luau` | **60 lần/giây**: ~5 `string.format`, 4 `FindFirstChild`, `getLocationInfo()` | **60 Hz** chỉ radar + thanh máu/thể lực; **10 Hz** chữ/MPH/sao truy nã; **3 Hz** tên đường + cache nhân vật ⇒ giảm ~85 % khối lượng CPU |
| `src/client/WeaponClient.luau` | dò `Character` mỗi frame để tìm vũ khí | cache + `ChildAdded/ChildRemoved`, chỉ dò lại khi đổi vũ khí |
| `src/server/VehicleManager.luau` | mỗi frame mỗi xe: tạo `OverlapParams.new()`, `FindFirstChild("LosSantos_Debris")`, `GetPartBoundsInBox`, ghi màu đèn hậu | `OverlapParams` **tái sử dụng**, cache thư mục rác, quét va chạm **20 Hz** (mỗi 3 frame), đèn hậu **chỉ ghi khi đổi trạng thái** |
| `src/server/LSCustomsService.luau` | mỗi 0,35 s: `FindFirstChild(..., true)` đệ quy + `FireClient` cho mọi người chơi gần | cache thư mục xe (dò lại 10 s), **chỉ gửi remote khi trạng thái đổi** (chống spam) |

---

## 5. Bật Instance Streaming (khuyến nghị mạnh nhất, cần làm 1 lần trong Studio)

`StreamingEnabled` là **thuộc tính không thể set bằng script**, nên:

- **Nếu bạn build bằng Rojo:** `default.project.json` đã bật sẵn
  (`StreamingEnabled = true`, min 64 / target 1024, `PauseOutsideLoadedArea`, `Improved`, `Opportunistic`).
- **Nếu bạn dùng plugin Studio Live Bridge:** mở Studio → chọn `Workspace` →
  Properties → **StreamingEnabled = ✔** (đặt `StreamingTargetRadius = 1024`).

Tác dụng với map này: chỉ ~1.800 part quanh người chơi được nạp thay vì 8.105 →
**giảm ~78 % bộ nhớ client và thời gian join**, tăng FPS trên máy yếu.

> ⚠️ Lưu ý khi bật streaming: mọi script phía client phải dùng `:WaitForChild()` cho part
> trong Workspace. Code hiện tại của dự án chỉ đọc `ReplicatedStorage` + remote + toán
> `WorldGrid` nên **an toàn 100 %** với streaming.

---

## 5.1. TỐC ĐỘ ĐỒNG BỘ LÊN STUDIO (Sync v18) — 30 giây → ~2 giây

Trước đây **mỗi lần publish** (dù chỉ sửa 1 dòng UI) tác vụ dựng thành phố đều
**xoá sạch rồi dựng lại toàn bộ ~14.000 part** → Studio đơ 20–40 giây mỗi lần.

`bridge/rebuild_world_action.luau` giờ chạy **ĐỒNG BỘ TĂNG DẦN**:

| Tình huống | Việc phải làm | Thời gian |
| :--- | :--- | :--- |
| Không đổi gì (hoặc chỉ sửa UI / NPC / vũ khí) | **BỎ QUA** — chỉ băm mã nguồn rồi thoát | **~0,1 s** |
| Đổi 1 module công trình (vd. Maze Bank) | Chỉ dựng lại **đúng module đó** (`DistrictRegistry.buildOne`) + tối ưu riêng phần vừa dựng | ~2–4 s |
| Đổi `CityFoundation` / `WorldGrid` / `PartBuilder` | Dựng lại nền + toàn bộ công trình (như cũ) | ~20–30 s |
| Đổi `VehicleBuilder` | Chỉ dựng lại dàn xe | ~0,5 s |
| Mất 1 công trình trong Studio (ai đó xoá tay) | Tự phát hiện và dựng lại đúng công trình đó | ~2–4 s |

**Nguyên lý:** băm **toàn bộ byte** mã nguồn của từng file trong `ReplicatedStorage.Shared`
(hàm băm `h = (h*31 + byte) % 2 147 483 647`), lưu vào `StringValue` tên `SyncHashes`
trong `workspace.LosSantos`, rồi lần sync sau so sánh.

> ⚠️ Bản đầu tiên lấy mẫu **mỗi 3 byte** cho nhanh — đã phát hiện lỗi: đổi 1 ký tự trong
> file ngắn vẫn ra **cùng mã băm** nên thành phố không cập nhật. Hiện băm **tất cả byte**
> (500 KB chỉ tốn ~0,05 giây, rẻ hơn 30 giây dựng lại rất nhiều).

**Van an toàn:** nếu dựng tăng dần lỗi ở bất kỳ module nào, tác vụ **tự động lùi về dựng lại
toàn bộ** để không bao giờ bị thiếu công trình.

**Ép dựng lại toàn bộ** (chạy trong Command Bar):
```lua
local sv = workspace.LosSantos:FindFirstChild("SyncHashes")
if sv then sv:Destroy() end
```

**Plugin cũng được tối ưu:**
1. In **thời gian từng công đoạn** (`Nạp script X s · Chạy tác vụ Y s · TỔNG Z s`) để biết chậm ở đâu.
2. **Poll thích ứng**: có thay đổi → 8 giây/lần; đã đồng bộ mới nhất → giãn ra **30 giây/lần**
   (trước đây tải lại gói 800 KB mỗi 8 giây kể cả khi không có gì mới).
3. Script **không đổi thì không ghi lại `Source`** (đã có từ trước) — không biên dịch lại 745 KB Lua.

## 5.2. THÀNH PHỐ SỐNG ĐỘNG (Sync v19) — 50 NPC + 4 xe có tài xế mà **không tụt FPS**

Trước v19 phố chỉ có **14 NPC** đứng loanh quanh 4 cụm, gần như không ai nhìn thấy. v19 nâng lên
**46 NPC đi bộ rải khắp 7 đại lộ + 4 xe có tài xế NPC**, tổng cộng **50 rig R6**. Đổi lại phải
xử lý 3 chỗ tốn kém:

| Chỗ tốn kém | Cách xử lý trong v19 | Kết quả |
|---|---|---|
| **Xoay khớp cho 50 NPC** | Server **không** xoay `Motor6D`. Server chỉ ghi `attribute "AnimState"` (1 lần mỗi khi đổi tư thế). Client `NPCAnimator.luau` xoay `Motor6D.Transform` ở **24 Hz**, bỏ qua NPC cách camera **> 260 stud** | Băng thông **+0 byte/giây**; 24 Hz đủ mượt, không cần 60 Hz |
| **4 xe × ~150 part di chuyển** | Neo **1 part duy nhất** (`Chassis`), hàn toàn bộ chi tiết còn lại vào nó bằng `WeldConstraint`, tắt `CanCollide/CanTouch`. Mỗi nhịp chỉ đổi **1 CFrame** | 600 part mà chỉ tốn 1 phép biến đổi/nhịp (thay vì 600) |
| **46 NPC × `MoveTo` mỗi 0,12 s** | `moveTo()` giữ nguyên cơ chế tiết chế (chỉ gọi lại khi đổi đích > 6 stud hoặc quá 1,1 s). Đích mới chỉ tính khi **tới nơi / kẹt 5 s**, không tính mỗi 4–9 s như trước | Số lần `MoveTo` giảm, NPC không rung lắc |

**Ngân sách part ước tính:** 50 NPC × ~10 part = `~500` part + 4 xe × `~150` = `~600` part
→ **~1.100 part động**. Với `StreamingEnabled` (bán kính `64/1024`) thì phần lớn trong số này
được stream theo vùng nhìn, nên vẫn nằm dưới ngưỡng khuyến nghị ~`50.000` instance hoạt động.

**Nếu máy yếu**, hạ 3 con số này ở đầu `src/server/NPCManager.luau` (không cần sửa chỗ khác):

```lua
local MAX_NPCS = 74          -- trần NPC cùng lúc
local AMBIENT_COUNT = 46     -- số NPC đi bộ khi khởi động  -> hạ về 24 nếu lag
local TRAFFIC_COUNT = 4      -- số xe có tài xế NPC          -> hạ về 2 nếu lag
```

Và hạ `UPDATE_HZ` (24) trong `src/client/NPCAnimator.luau` xuống `16`, hoặc `CULL_DISTANCE`
(260) xuống `160` để bớt rig phải vẽ animation.

**Lưu ý khi test:** NPC + xe chỉ sinh ra **khi bấm Play** (là script server), không phải lúc sync.
Mở Output xem 2 dòng `[NPC] Đã dựng … NPC rải khắp vỉa hè thành phố` và
`[NPC] Đã thả … xe có TÀI XẾ NPC chạy vòng quanh phố`.

## 6. Các bước tối ưu tiếp theo (chưa làm, xếp theo mức lợi)

1. **Gom cụm tĩnh thành `MeshPart`/Union theo cụm 4×4 stud** cho phần *không phá huỷ*
   (vỉa hè, mặt đường, tường bao) → giảm draw call, giữ nguyên khối phá huỷ.
2. **Giới hạn đèn động**: mỗi `PointLight`/`SpotLight` bật bóng là cực tốn; chỉ giữ
   đèn có bóng cho biển hiệu chính, còn lại dùng Neon (không tốn light).
3. **LOD bằng `ModelStreamingMode`**: đặt `Persistent` cho cụm trung tâm (Legion Square)
   và để phần xa stream bình thường.
4. **Đo bằng MicroProfiler** (F9 → MicroProfiler) sau khi bật streaming để xác nhận
   draw call < 1.000 và triangle < 1.000.000 như khuyến nghị của Roblox.
