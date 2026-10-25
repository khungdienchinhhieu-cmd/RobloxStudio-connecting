# ✅ BIÊN BẢN NGHIỆM THU ĐẠT: `AGENT_2_SUPERMARKET_247` (Siêu thị 24/7 — `Plot_C3_West`)

- **Người nghiệm thu:** Agent Chính (`arena/b37b6115-robloxstudio-connecting`)
- **Nhánh tác giả:** `arena/bc783dbc-robloxstudio-connecting` — commit `52d0eff`
- **File tích hợp:** `src/shared/World/Modules/Plot_C3_Supermarket247.luau` (`38,192B`)
- **Kết luận:** ✅ **ĐẠT — tích hợp vào bản Sync v10.** Không cần sửa code của tác giả.

---

## 1. Số liệu đo tự động (Luau VM + quét AABB bằng Python)

| Hạng mục kiểm tra | Kết quả | Đánh giá |
| :--- | :--- | :--- |
| Khối dựng (`BasePart`) | **`934`** | Đúng mật độ chi tiết yêu cầu |
| Máu ẩn (`Destructible = true`) | **`933 / 934` (`99,9 %`)** | ✅ cơ chế phá huỷ phủ gần tuyệt đối |
| Khối va chạm | `892` | Hợp lý (42 khối trang trí/kính đã tắt) |
| Ranh giới thực tế | `X 137,00 … 212,00` · `Z 26,95 … 123,00` · `Y 1,15 … 27,41` | ✅ **`0` khối tràn biên** ô `Plot_C3_West` |
| Tấm đồng phẳng Z-fighting | **`0` cặp** | ✅ |
| Khối trùng vị trí (dupe) | **`0`** | ✅ |
| Khối lơ lửng (không có gì đỡ) | **`0`** (sai số `0,16` stud) | ✅ |
| Cửa đi bộ (R15 `5,45` stud) | `X = 175`, `Z = 92`, cao **`9`** stud, rộng `6` stud | ✅ dư thông thuỷ `+3,5` stud |
| Cửa cuốn nhận hàng (nhân viên/xe nâng) | `X = 143`, `Z = 38`, **`16 × 12`** stud | ✅ |
| Bãi đỗ xe trước tiệm | gờ chặn bánh `WheelStop` + vạch `ParkLine` | ✅ |
| Đèn trần / ống gió vs trần | thiết bị `y = 15,6` < `RoofSlab y = 16,9` | ✅ **`1,3`** stud khe hở, không xuyên |
| Cửa cuốn vs `RollupHeader` | trần `15,1` > lá cửa max | ✅ |

## 2. Kiểm tra "đọc được bằng mắt" (render 3D offline)

Đã render 7 góc từ chính dữ liệu scene (ảnh của tác giả: [`agents/reviews/Plot_C3_Supermarket247/`](../../agents/reviews/Plot_C3_Supermarket247/)):

- ✅ **Mặt tiền 24/7**: mái hiên sọc xanh lá – trắng – đỏ cam, bảng hiệu lớn `46 × 4,4` stud,
  cột pylon đứng `(175, 24, 86)`.
- ✅ **Vách kính chia ô rời**: từng ô có máu riêng → bắn vỡ từng mảnh như GTA V.
- ✅ **Nội thất full**: 3 dãy kệ hàng đầy sản phẩm nhiều màu, quầy thu ngân + máy tính tiền,
  ATM góc tường, tủ lạnh nước ngọt phát sáng, máy Slushie.
- ✅ **Khu nhận hàng**: cửa cuốn + sàn nâng (dock) `X 138…143, Z 29…47`.

## 3. Hai ghi chú nhỏ (KHÔNG chặn nghiệm thu, đã xử lý tự động)

1. **`MainSignBoard` (46 × 4,4 stud)** chỉ là tấm phẳng màu trơn cho tới khi `SurfaceGui`
   render chữ. Trong ảnh render offline mặt biển trắng trơn là **do renderer không vẽ GUI**,
   trong Studio sẽ hiện đủ chữ `24/7 SUPERMARKET`. Agent Chính đã tự động hạ
   `PixelsPerStud` (→ canvas ≤ 1.100 px) và đặt `MaxDistance = 340` qua `PerfOptimizer`
   để biển không ngốn fill-rate khi ở xa.
2. **`62` part siêu mỏng (`< 0,12` stud)**: `AwningTopStripe` ×20, `GlassShelf` ×12,
   `ParkLine` ×8, `WheelStopStripe` ×6, `Crosswalk` ×6, `AisleHanger` ×6. Đây là **chi tiết
   sơn kẻ/vạch kính**, lớp `PerfOptimizer` đã tắt `CanCollide/CanTouch/CanQuery` và
   `CastShadow` nên **không ảnh hưởng hiệu năng**, đồng thời chúng được đặt lệch `≥ 0,03`
   stud so với bề mặt nền nên **không Z-fighting**.

## 4. Hiệu năng sau khi tích hợp (đo trên cả scene `8.105` part)

`PerfOptimizer` chạy sau `DistrictRegistry.buildAll` cho kết quả:

```
[PerfOptimizer] 7191 parts | CanCollide 4359 → 2975 | CanTouch 7191 → 0
                CanQuery 7187 → 7024 | CastShadow 4670 → 3769
                SurfaceGui 36 | -11392 attributes
```

Chi tiết đầy đủ: [`docs/PERFORMANCE.md`](../../docs/PERFORMANCE.md).
