# 🎨 UI GUIDE — Los Santos Modular (chuẩn GTA V)

> Mọi Agent làm UI/HUD phải dùng đúng bảng màu, font và kích thước dưới đây để
> giao diện **đồng bộ 100%** với HUD hiện tại (viết lại ở Sync v12).

---

## 1. Design tokens

| Vai trò | Hex | RGB (Luau) |
| :--- | :--- | :--- |
| Nền panel | `#0A0C10` | `Color3.fromRGB(10, 12, 16)` |
| Nền panel sáng | `#12171F` | `Color3.fromRGB(18, 23, 31)` |
| Đường viền | `#26303F` | `Color3.fromRGB(38, 48, 64)` |
| Chữ chính | `#F1F5F9` | `Color3.fromRGB(241, 245, 249)` |
| Chữ phụ | `#94A3B8` | `Color3.fromRGB(148, 163, 184)` |
| Tiền mặt (xanh GTA) | `#72CC72` | `Color3.fromRGB(114, 204, 114)` |
| Máu | `#56BA56` | `Color3.fromRGB(86, 186, 86)` |
| Giáp | `#3B9BE8` | `Color3.fromRGB(59, 155, 232)` |
| Thể lực | `#EEC135` | `Color3.fromRGB(238, 193, 53)` |
| Nguy hiểm / truy nã | `#EF4444` | `Color3.fromRGB(239, 68, 68)` |
| Khu vực (vàng) | `#F0C642` | `Color3.fromRGB(240, 198, 66)` |

**Accent theo loại vũ khí** (dùng cho viền/thanh nhấn):
`#94A3B8` tay không · `#F59E0B` cận chiến · `#60A5FA` súng ngắn ·
`#38BDF8` súng ngắn tự động · `#2DD4BF` SMG · `#4ADE80` súng trường ·
`#FB923C` shotgun · `#C084FC` bắn tỉa.

## 2. Font

- Tiêu đề / số lớn: `Enum.Font.GothamBlack`
- Nhãn / nút: `Enum.Font.GothamBold`
- Nội dung: `Enum.Font.GothamMedium`
- **Không dùng `TextScaled`** (tốn ~10× thời gian layout — xem `docs/PERFORMANCE.md`).
- Chữ trên ảnh sáng phải có `TextStrokeTransparency ≈ 0.15–0.35` hoặc nền panel mờ.

## 3. Hình khối & khoảng cách

| Thành phần | Quy chuẩn |
| :--- | :--- |
| Bo góc panel | `UICorner` 6–8px |
| Bo góc chip/nút nhỏ | 5–6px |
| Bo tròn hoàn toàn (badge) | `UDim.new(1, 0)` |
| Viền | `UIStroke` dày 1–1.5px, `Color #000` + `Transparency 0.5–0.6` |
| Lề màn hình | 22px (trái/phải), 16–20px (trên/dưới) |
| Khoảng cách giữa cụm | ≥ 14px |
| Kích thước chip | cao 26px, chữ 11px |

## 4. Bố cục HUD (không được chồng lấn)

```
┌──────────────────────────────────────────────────────────────┐
│ [H] MENU TEST  [TAB] VŨ KHÍ                 ★★★★★   (26,16)  │
│                                               $5,000 (panel)  │
│                                                              │
│                                                              │
│  ┌─ FEED (258×56) ─────────┐                                 │
│  └─────────────────────────┘                                 │
│  ┌─ RADAR 258×168 ─────────┐            ┌ WEAPON CARD 252×76 ┐│
│  └─────────────────────────┘            └───────────────────┘│
│  ▬▬▬ Máu (258×5)                         LEGION SQUARE        │
│  ▬▬▬ Giáp (258×5)                        Power Street   (22px)│
│  ▬▬▬ Thể lực (258×5)   (22,20)                                │
└──────────────────────────────────────────────────────────────┘
```

- Radar: `left 22, bottom 20, 258×168`, bo góc 10, viền trong sáng 1px.
- 3 thanh chỉ số **xếp chồng**, mỗi thanh cao **5px**, cách nhau **2px**.
- Thẻ vũ khí: `right 26, bottom 86, 252×76` (ẩn khi tay không / khi đang lái xe).
- Tên đường + khu vực: góc dưới phải, sát đáy 22px.
- Feed: `left 22`, đáy = `RADAR + 76` để không đè radar.

## 5. Vòng chọn súng (đã chuẩn hoá)

| Thông số | Giá trị |
| :--- | :--- |
| Phím mở | Giữ `TAB`, thả để trang bị · `ESC` huỷ |
| Số ô | **9 ô**, ô 1 ở **trên cùng**, thuận chiều kim đồng hồ (**40°/ô** = `2π/9`) |
| Bán kính vòng | 196px, ô 108×108, bo góc 18px |
| Vùng chết tâm | < 54px → giữ nguyên ô đang chọn |
| Ô đang chọn | Viền accent 3px + phóng 1.09× + nền pha accent 22% |
| Tâm | Danh mục (10px) · Tên súng (17px) · Đạn (20px, accent) · Gợi ý (9px) |
| Đổi nhanh | Phím `1..9` khi vòng đóng (ô 9 = RPG-7) |

### 5.1 BỐN chỗ BẮT BUỘC sửa khi thêm vũ khí mới

`SLOT_COUNT` và `SLOT_GAP` **đã được tách thành hằng số** — nhưng vẫn còn 3 nơi phải cập nhật cùng lúc, thiếu 1 chỗ là vòng vẽ sai:

1. `SLOT_COUNT` (dòng ~35) — tổng số ô.
2. `DEFAULT` (dòng ~40) — danh sách dự phòng khi server chưa gửi `WeaponSync`.
3. `keySlots` trong `UserInputService.InputBegan` — bảng phím `1..9` -> ô.
4. `buildIcon()` — thêm nhánh `elseif kind == "<icon>"` vẽ icon bằng `Frame`, nếu không ô sẽ trống trơn.

Bản demo browser `bridge/hud-demo.html` phải sửa **y hệt**: `SLOT_COUNT`, `angleToSlot()` (chia `360 / SLOT_COUNT`), `WEAPONS[]` và `ICONS{}`.

## 6. Quy tắc hiệu năng UI

1. Không tạo/huỷ Frame mỗi frame — chỉ đổi `Size`/`Text`/`Position`.
2. Chia nhịp cập nhật: **60 FPS** cho thanh/radar, **10 FPS** cho chữ, **3 FPS** cho tên đường.
3. Cache `string.format` (chỉ gọi khi giá trị đổi).
4. `ScreenGui.ResetOnSpawn = false` + dọn ScreenGui cũ trước khi mount.
5. Toàn bộ icon vẽ bằng `Frame` — **không upload asset rời** (repo không có quyền upload).
