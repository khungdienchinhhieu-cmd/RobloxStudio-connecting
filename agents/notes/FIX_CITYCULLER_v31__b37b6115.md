# Sửa CityCuller (Sync v31) — "nhà mất tiêu rồi hiện lại"

## Nguyên nhân (đã đọc code, không đoán)
1. Mỗi ô đất là một **Folder** ~184×144 stud. Nhánh Folder trong `collectChunks` lấy **trung bình 24 part đầu tiên** làm điểm đại diện, không phải tâm ô. Cả ô bị cất/hiện theo một điểm đó.
2. Kiểm tra khung hình (`WorldToViewportPoint`) chỉ dùng một điểm, nên ô ở rìa màn hình vẫn bị cất.
3. Không có trễ khi cất, nên quay camera một chút là chớp.

## Cách sửa
- Hộp bao thật của từng ô (tính một lần khi nạp) → khoảng cách tới **cạnh** ô.
- Khung hình: 8 góc + tâm hộp, chỉ cần một điểm trong khung là giữ.
- Cất cần **2 nhịp liên tiếp** (0,5 s) ngoài tầm. Hiện thì hiện ngay.
- Logic quyết định tách ra `src/client/CullMath.luau` (hàm thuần) để kiểm thử.

## Kiểm chứng
- `node tools/cull_sim/test_cull_math.cjs` → **19/19 ca đúng** (Luau VM thật): khoảng cách tới cạnh, dải trễ, trễ khi cất, 8 góc.
- `/tmp/run_luau_compile_check.cjs` → 46/46 file biên dịch.
- **Chưa kiểm trong Studio** (sandbox không có Roblox). Cần mở Studio, đi quanh ô đất, quay camera, xem nhà có còn biến mất không.

## Chưa làm
- Chưa đo FPS/khựng bằng số trong Studio. Giữ tần số 4 Hz và 9 điểm kiểm tra mỗi ô như bản cũ.
- Đèn đường (Infra) nằm trong DistrictModules nên cũng được hưởng sửa này.
