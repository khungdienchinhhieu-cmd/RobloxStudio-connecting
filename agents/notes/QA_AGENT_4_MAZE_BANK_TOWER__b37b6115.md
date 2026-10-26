# QA của Agent Chính — AGENT_4_MAZE_BANK_TOWER (Plot_D2)

Nguồn: `origin/arena/bc783dbc-robloxstudio-connecting` · file `src/shared/World/Modules/Plot_D2_MazeBankTower.luau` (1 882 dòng)
So với bản đang có trên `main` (`c1eac10`, nghiệm thu 9,2/10).

## Kết quả kiểm lại bằng harness (không tin số tự báo)

| Hạng mục | Bản nộp (bc783dbc) | Bản đang có (main) |
|---|---|---|
| BasePart | 2 292 | 2 312 |
| Khối có máu ẩn | 2 250 (98,2 %) | — |
| Cặp đè > 6 stud³ (`overlap_check`) | **0** | 90 |
| AABB | −83..83 · 1,15..165 · −188..−63 (trong ô) | giống |
| Tên trùng / khối nhỏ còn va chạm / CanTouch / SurfaceGui sai | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Build ok | true | true |
| Giao diện module (Id, PlotId, Order 40, build) | đúng | đúng |
| Attribute (MainEntrance, LobbyDoors, VehicleRamp×2, Helipad, TowerHeightStuds, DestructibleStore) | đủ | đủ |
| Quầy D2_DEPOSIT / D2_WITHDRAW | ✅ trống, nền 1,27 | ✅ |
| Số ảnh QA | 21 ảnh (`agents/reviews/AGENT_4_MAZE_BANK_TOWER/`) | — |

Ảnh mặt đứng chính (`01_hero_south_facade.jpg`) đã xem: khớp mô tả, không thấy khối lơ lửng hay lệch tầng.
Chưa xem 20 ảnh còn lại, đặc biệt nội thất và hầm đỗ xe.

## Ghi chú
- Harness in dòng `Thiếu MaxPartHealth: undefined` cho cả hai bản. Đây là lỗi nhãn trong công cụ, không phải lỗi của bản nộp. Sẽ sửa riêng.
- Nhánh bc783dbc được tách từ một `main` cũ. Bản nộp chỉ đụng đúng 1 file, nên tích hợp không xung đột với các thay đổi sau đó.
- Bản nộp không sửa WorldGrid, PartBuilder, CityFoundation hay DistrictRegistry.

## ⛔ ĐÍNH CHÍNH (Agent Chính, 13:40)
Kết luận "0 cặp đè" ở trên là **SAI**. Lần kiểm đó mình truyền đường dẫn `/tmp/...` vào
`overlap_check.cjs`; công cụ chỉ đọc thư mục module nên không kiểm file đó và vẫn in ✅.
Kiểm lại đúng cách (file đã đặt vào `src/`): **bản nộp cũng có 90 cặp đè > 6 stud³**, ví dụ
`FountainRim_N ✕ GrandStairA_Step4`, `TowerTopSignW ✕ AcTop_2_W`, `MECH_WallW ✕ AcTop_2_W`.
Bản đang chạy trên main cũng 90 cặp. Vì vậy **bản nộp KHÔNG tốt hơn** ở tiêu chí đè.
Quyết định: **giữ bản đang chạy, không thay D2.** Yêu cầu Agent 4 (bc783dbc) sửa 90 cặp đè rồi nộp lại.

## Kết luận (đã sửa)
**CHƯA ĐẠT.** Yêu cầu sửa: 0 cặp đè theo `overlap_check.cjs Plot_D2`, và chạy lại công cụ bằng đúng cách.

## Kết luận cũ (đã thu hồi)
**ĐẠT — đề nghị thay bản D2 hiện tại** (0 cặp đè thay vì 90, ít hơn 20 part, cùng giao diện).
Chờ bạn đồng ý trước khi thay trên nhánh chính, vì đây là thay đổi công trình đã nghiệm thu.
