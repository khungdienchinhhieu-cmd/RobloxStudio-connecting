# NHÀ "ÍT PART" MÀ VẪN BỂ ĐƯỢC — Nghiên cứu kỹ thuật
> ⚠️ **Cập nhật `Sync v23`:** biệt thự mẫu `Plot_E1_PacificBluffs` đã được **gỡ khỏi thành phố**
> (Chủ dự án: kiểu "ít part" nhìn không đẹp bằng công trình chi tiết). Tài liệu này giữ lại
> vì **kỹ thuật** vẫn dùng: `DestructibleShell.luau` tiếp tục là chuẩn cho tấm vỏ / panel kính
> phá huỷ của mọi công trình do Agent phụ dựng.


> Sync v21 · Trả lời câu hỏi: *"cách nào làm nhà bằng ít part nhưng vẫn có cơ chế bể như vậy được không?"*
> **Trả lời ngắn: ĐƯỢC. Cùng một căn nhà, từ 3 462 part xuống 176 part (−94,9 %), bề mặt vẫn bể 100 %.**

---

## 1. Vì sao nhà hiện tại tốn hàng nghìn part?

Không phải vì "cần nhiều part để bể". Đo trên 2 công trình đã nghiệm thu:

| Công trình | Số part | Trong đó part phá huỷ | Nếu chỉ tính "bề mặt cần bể" |
|---|---:|---:|---:|
| Los Santos Customs (`Plot_C1`) | 3 462 | 3 396 (98,1 %) | ~600 |
| Đồn LSPD Mission Row (`Plot_C3`) | 4 639 | 4 620 (99,6 %) | ~800 |

**~85 % số part không dùng để bể** — chúng tồn tại vì 2 lý do:

1. **Hoa văn làm bằng part** — mỗi viên gạch, mỗi đường ron, mỗi viền ốp là 1 `Part` riêng.
   Một bức tường 40 × 12 stud đã tốn `40 × 12 / (2 × 0.8) ≈ 300` viên.
2. **Trang trí làm bằng part** — lan can (mỗi cột 1 part), đèn, chậu cây, biển hiệu...

Cái thực sự cần bể chỉ là **bề mặt tường + kết cấu chịu lực**.

---

## 2. Kỹ thuật: 4 tầng, chỉ tầng 2–3 phá huỷ

```
┌─────────────────────────────────────────────────────────────┐
│ TẦNG 4  TRANG TRÍ        ~30 part   Destructible = false    │
│         đèn, biển, lan can, chậu cây  (Massless, không va chạm)│
├─────────────────────────────────────────────────────────────┤
│ TẦNG 3  CHI TIẾT GIẢ       ~10 part   Destructible = false  │
│         HOA VĂN GẠCH / NGÓI = Texture, KHÔNG phải part      │
├─────────────────────────────────────────────────────────────┤
│ TẦNG 2  TẤM VỎ TƯỜNG      ~52 part   Destructible = TRUE ⭐ │
│         1 tấm = 1 Ô CỬA SỔ (8–11 × 10 stud), không phải 1 viên│
├─────────────────────────────────────────────────────────────┤
│ TẦNG 1  KẾT CẤU CHỊU LỰC  ~14 part   Destructible = TRUE ⭐ │
│         móng, sàn tầng, cột góc, cầu thang, mái             │
└─────────────────────────────────────────────────────────────┘
```

### Bí quyết 1 — Texture thay cho part hoa văn

`Texture` là một **instance trang trí**, gắn lên mặt của `Part`, **không có khối vật lý,
không tốn slot render**. Một tấm vỏ 11 × 10 stud + `Texture` gạch `StudsPerTile 4×4`
trông y hệt 60 viên gạch xếp — nhưng là **1 part**.

```lua
local tex = Instance.new("Texture")
tex.Texture = "rbxasset://textures/Bricks1_1.png"  -- texture có sẵn trong client
tex.StudsPerTileU = 4
tex.StudsPerTileV = 4
tex.Face = Enum.NormalId.Front
tex.Parent = wallPart
```

> **Quy tắc vàng #1:** Không bao giờ dùng part để tạo *hoa văn*. Dùng `Texture` / `Material`.

### Bí quyết 2 — Chia tấm theo KHOANG KIẾN TRÚC

Chia tường theo **ô cửa sổ** (8–11 stud), không theo **viên gạch** (2 stud).
Một mặt tiền 44 stud = **4 khoang**, không phải 22 cột gạch.

Đây là mức chia tự nhiên của kiến trúc: mắt người nhìn thấy "ô cửa", không nhìn thấy "viên gạch thứ 37".

### Bí quyết 3 — Mảnh vỡ TỰ CO GIÃN theo kích thước khối

Đây là thay đổi quan trọng nhất, nằm ở `DestructionManager.fractureWorldBlock`.

**Trước v21** — luôn vỡ 2 hoặc 4 mảnh:

```lua
local subCount = if (sz.X * sz.Y * sz.Z) > 12 then 4 else 2
```

→ Vỡ 1 viên gạch 2×0.8×1 = 2 mảnh ✅
→ Nhưng vỡ 1 **tấm tường 11×10** cũng chỉ 4 mảnh to đùng ❌ → nhìn như miếng bìa carton.

**Từ v21** — số mảnh tỉ lệ thể tích, chia theo **lưới 3D**:

```lua
local subCount = math.clamp(math.floor(volume / 6) + 2, 2, 14)
-- rồi chia thành lưới nx × ny × nz
```

| Khối bị bắn vỡ | Kích thước | Số mảnh |
|---|---|---:|
| Viên gạch | 2 × 0.8 × 1 | **2** (như cũ) |
| Trụ cột | 1.6 × 33 × 1.6 | 8 |
| Tấm vỏ có cửa sổ | 11 × 6.6 × 0.7 | **10** |
| Tấm vỏ đặc | 11 × 10.6 × 0.7 | **14** |
| Tấm hông | 9.3 × 10.6 × 0.7 | **13** |

→ **1 part lớn khi vỡ cho ra 10–14 mảnh** — cảnh đổ y như 60 viên gạch nổ tung,
nhưng lúc *chưa* vỡ thì chỉ tốn **1 part**.

### Bí quyết 4 — Sập dây chuyền bằng `StructuralRow` (đã có sẵn)

Chỉ cần 14 part kết cấu là đủ để cả căn nhà đổ theo tầng: mỗi part mang
`StructuralRow` (1 = móng, 2 = tầng 1, 4 = tầng 2, ...). Khi 1 part vỡ, hệ thống tự
đánh sập các part `Row + 1` nằm ngay trên nó.

---

## 3. Kết quả đo được

Chạy harness (`mock Roblox API`) trên công trình mẫu **Biệt thự Pacific Bluffs (`Plot_E1`)**:

```
TONG_PART              = 176
  thân nhà             =  75   (14 kết cấu + 52 tấm vỏ + 9 trang trí)
  sân vườn/hồ bơi/cây  = 101
PART_BE_DUOC           =  84   (47,7 %)
PART_TRANG_TRI         =  92
PART_DUOI_MAT_DAT      =   0   ← không có part lơ lửng
PART_TRAN_BIEN_X       =   0   ← không tràn biên trục X
PART_TRAN_BIEN_Z       =   0   ← không tràn biên trục Z
KHI_BE_HET             = 84 tấm vỏ → 894 mảnh (TB 10,6 mảnh/tấm)
THOI_GIAN_DUNG         = 0,036 s
```

**So sánh trực tiếp:**

| | Los Santos Customs (cách cũ) | Biệt thự Pacific Bluffs (cách mới) |
|---|---:|---:|
| Số part | 3 462 | **176** |
| Diện tích sàn | ~1 100 m² | ~1 150 m² |
| Part phá huỷ được | 3 396 | 84 |
| Mảnh vỡ khi phá sạch | ~6 800 | **894** |
| **Chênh lệch** | — | **−94,9 % part** |

---

## 4. Cách dùng trong công trình tiếp theo

```lua
local DestructibleShell = require(ReplicatedStorage.Shared.World.DestructibleShell)

local house, stats = DestructibleShell.buildHouse({
    parent       = myModel,
    name         = "Plot_E3_LittleSeoul",
    center       = Vector3.new(-432, 1.15, 57),  -- TÂM MÓNG, Y = mặt đất
    width        = 40,
    depth        = 26,
    floors       = 3,
    floorHeight  = 11,
    wallColor    = Color3.fromRGB(226, 214, 196),
    trimColor    = Color3.fromRGB(242, 240, 234),
    roofColor    = Color3.fromRGB(96, 74, 62),
    pattern      = "brick",   -- "brick" | "stucco" | nil
    baysX        = 4,         -- số khoang cửa mặt trước/sau
    baysZ        = 3,         -- số khoang cửa mặt hông
})
-- stats = { structural = 14, shell = 52, decor = 9, total = 75 }
```

Muốn **trang trí thêm** thì luôn dùng:

```lua
part.CanCollide     = false
part.CanQuery       = false
part.CanTouch       = false
part.CastShadow     = false
part.Massless       = true
part:SetAttribute("Destructible", false)
```

---

## 5. Khi nào KHÔNG nên dùng kỹ thuật này

| Trường hợp | Nên dùng |
|---|---|
| Công trình biểu tượng (LS Customs, LSPD, Maze Bank) — người chơi đứng nhìn gần | Cách cũ: gạch rời từng viên, tối đa chi tiết |
| Nhà dân, cửa hàng, kho bãi rải khắp bản đồ (hàng chục cái) | **Tấm vỏ + Texture** (kỹ thuật này) |
| Vật thể nhỏ (thùng rác, ghế, biển báo) | 1 part + HP thấp, không cần Texture |

**Chiến lược tổng thể:** 4 công trình trung tâm giữ cách cũ (đã nghiệm thu 9.0–9.2/10),
toàn bộ **4 ô đất mới** ở rìa bản đồ dùng cách mới → mở rộng thành phố mà **không tăng số part**.

---

## 6. Giới hạn cần biết

- `Texture` là **ảnh 2D dán lên mặt phẳng** → chỉ đẹp khi nhìn vuông góc. Nhìn nghiêng
  rất xa sẽ thấy texture trượt. Với khoảng cách > 150 stud, hãy tắt (`Texture.Transparency = 1`)
  hoặc dựa vào `StreamingEnabled`.
- Tấm vỏ **quá lớn** (> ~16 stud) sẽ khiến 1 viên đạn xoá cả mảng tường → HP phải tăng theo
  diện tích. Công thức đang dùng: `HP = clamp(width × height × 1.5, 60, 900)`.
- `fractureWorldBlock` sinh ra 2–14 part **mỗi lần vỡ** → phá sạch 1 căn nhà mới sinh 894 part,
  và chúng tự huỷ sau 7,5 giây (`Debris`). Đừng giảm thời gian này xuống dưới 5 giây.
