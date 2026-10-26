# Harness mô phỏng NPC (chạy ngoài Roblox Studio)

Chạy **thật** `src/server/NPCManager.luau` bằng Luau WASM với một lớp mock API Roblox
(`Instance`, `CFrame`, `Vector3`, `Enum`, `Color3`, `Players`, `Workspace.Raycast` trả `nil`,
`Humanoid:MoveTo` có "vật lý" giả) + **scheduler coroutine** + **đồng hồ mô phỏng**
(`os.clock` giả) nên 90 giây trong game chạy xong trong ~1 giây thật.

```bash
npm i @luau-rs/luau        # hoặc copy package vào /tmp/luau-check
node tools/npc_sim/run.cjs
```

Kết quả mong đợi (Sync v24):

```
getStats: sống=93 r15=93 xe=8
[NPC diagnose] sống=93 · điểm vỉa hè=267 · jogger=3 · hoạt động: IDLE=4, LOOK=11, PHONE=8, TALK=10, WALKING=55, WINDOW=5
twin: ok=true model=true
di chuyển trong 60s: 84/93 NPC đi > 8 stud (xa nhất 557)
số cảnh báo: 0

✅ PASS — thành phố có NPC sống, đi lại và làm việc, không lỗi.
```

`93 = 84 NPC đi bộ + 1 bản sao người chơi + 8 tài xế xe`. 8 NPC không tính "đi > 8 stud"
là 8 tài xế (đúng thiết kế: họ ngồi trong xe).

## Vì sao cần harness này

`Sync v23` bị lỗi **"thành phố trống, chỉ có 1 NPC"** mà không có một dòng log nào, vì
`spawnAmbient` gọi `pcall(NPCManager.spawn, ...)` và **nuốt mọi lỗi**. Harness chạy đúng
đoạn code đó nên lỗi hiện ra ngay. Nguyên nhân đã tìm được:

```lua
-- SAI (v21 → v23):
local r15 = NPCAppearance.build(...)      -- build() trả 4 giá trị, gán 1 biến → chỉ giữ Model
model, hum, hrp, head = r15               -- băm Model theo chỉ số 1..4 → hum/hrp/head = nil
-- → hrp.Position nổ ở dòng sau → pcall nuốt lỗi → 0/84 NPC

-- ĐÚNG (v24):
local model, hum, hrp, head = NPCAppearance.build(...)
```

## Giới hạn của harness

* Mock không mô phỏng va chạm / vật lý thật → chỉ đo **logic** (dân số, hoạt động, di chuyển).
* `Workspace.Raycast` luôn trả `nil` → luôn đi qua nhánh **dự phòng hình học** của `findGround`.
  Đó cũng là nhánh cần test nhất (Studio hay trượt tia khi part nền `CanQuery = false`).
* Render, animation, âm thanh không kiểm được — phải xem trong Studio.
