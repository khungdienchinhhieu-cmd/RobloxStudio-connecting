# PROMPT — Cấu trúc lại cơ chế nối Roblox Studio ↔ GitHub

Bạn là agent kỹ thuật chịu trách nhiệm **cơ chế đồng bộ** giữa repo GitHub `khungdienchinhhieu-cmd/RobloxStudio-connecting` và Roblox Studio. Hiện tại cơ chế đang chạy ổn. Nhiệm vụ của bạn là **tái cấu trúc** nó theo đúng thiết kế dưới đây, không đổi trải nghiệm người dùng, không đổi tên nhánh.

## 1. Mục tiêu
- Người dùng bấm một dòng lệnh trong Command Bar của Studio là plugin tải đúng phiên bản code từ GitHub và áp vào Studio.
- Mỗi lần publish có **version + hash + danh sách file + tác vụ dựng lại** để Studio biết phải làm gì.
- Không cần token người dùng trong Studio. Mọi thứ đi qua URL công khai (`raw.githubusercontent.com`) theo **commit SHA cố định** (không dính cache).

## 2. Kiến trúc hiện tại (phải giữ nguyên ý tưởng)
| Thành phần | File | Vai trò |
|---|---|---|
| Đóng gói | `bridge/compiler.mjs` | Đọc `src/` theo `default.project.json` (Rojo), tạo gói đồng bộ, dựng dòng lệnh Command Bar. |
| Publish | `bridge/publish.mjs` | Tăng version, ghi `studio-sync.json`, đính kèm tác vụ dựng lại (`bridge/rebuild_world_action.luau`), commit, push. Cờ `--no-action` để tắt tác vụ. |
| Gói đồng bộ | `studio-sync.json` | Có `version`, `hash`, `repo`, `branch`, `updatedAt`, `files[]` (đường dẫn repo, ClassName, bytes), `actions[]`. |
| Plugin | `plugin/StudioLiveBridge.server.luau` | Chạy trong Studio. Đọc commit mới nhất, tải `studio-sync.json` theo SHA, áp file, chạy tác vụ, báo kết quả. |
| Máy chủ cục bộ | `bridge/server.mjs` (cổng 8080) | Trang điều khiển, nhận trạng thái, hiển thị gói và tác vụ. |
| Bộ đàm QA | `bridge/agent-radio.mjs`, `bridge/agent-watch.mjs`, `bridge/qa-radar.mjs` | Các agent trao đổi trạng thái qua file/chat. |
| Theo dõi nền | `tools/watch/file_watch.mjs` | Poll GitHub bằng `gh api`, ghi cảnh báo vào `tools/watch/.state/ALERTS.log` (đã gitignore). |
| Kiểm tra | `tools/sync_sim/check_bundle.cjs` | So gói với repo: số file, hash, tác vụ, file thiếu. `--fresh` dựng lại từ repo. |

Luồng hiện tại:
1. Sửa `src/` → `node bridge/publish.mjs "thông điệp"`.
2. Script tạo `studio-sync.json` mới, commit, push lên nhánh `arena/b37b6115-robloxstudio-connecting`.
3. Script in dòng Command Bar gắn **commit SHA** mới, ví dụ:
   `local h=game:GetService("HttpService") h.HttpEnabled=true loadstring(h:GetAsync("https://raw.githubusercontent.com/<owner>/<repo>/<SHA>/plugin/StudioLiveBridge.server.luau",true))()`
4. Plugin đọc gói theo SHA đó, áp file, chạy tác vụ dựng lại.

Bất biến cần giữ:
- **Luôn kiểm tra trước khi kết luận đã publish**: chạy `check_bundle.cjs`. Lỗi đã gặp: gói có 43 script nhưng `src/` có 44 file → file mới chưa có trong gói.
- **Dòng Command Bar luôn gắn SHA cụ thể**, không trỏ vào nhánh (để tránh cache).
- Nếu gói không có tác vụ dựng lại, Studio **không** dựng lại thành phố. Đừng bỏ tác vụ mặc định nếu không có lý do rõ.
- Không bao giờ đưa token, mật khẩu hay cookie vào file repo hoặc gói. `.gitignore` đã chặn `.rbxl`, `.rbxlx`, `sourcemap.json`.

## 3. Việc cần làm
1. **Đọc và ghi lại** luồng hiện tại (mục 2) vào `agents/notes/SYNC_ARCHITECTURE.md`, kèm sơ đồ text. Ghi rõ những gì bạn đã xác minh bằng code, không suy đoán.
2. **Tách lớp** cho dễ bảo trì, mà không đổi hành vi bên ngoài:
   - `bridge/lib/manifest.mjs`: đọc/ghi và xác thực `studio-sync.json` (schema: version, hash, files, actions).
   - `bridge/lib/build.mjs`: tạo gói từ `src/` (dùng lại `compiler.mjs`).
   - `bridge/lib/command.mjs`: sinh dòng Command Bar với SHA.
   - `bridge/publish.mjs` chỉ còn điều phối các lớp trên.
3. **Thêm kiểm tra schema** trong `check_bundle.cjs`: thiếu trường, hash không khớp, `files[]` trùng đường dẫn, tác vụ thiếu file.
4. **Thêm cờ `--dry-run`** cho `publish.mjs`: in gói và dòng Command Bar, không ghi và không push.
5. **Giữ tương thích**: plugin hiện tại phải đọc được gói mới mà không sửa Studio. Nếu bắt buộc đổi định dạng, tăng `schemaVersion` và giữ đọc được bản cũ.

## 4. Ràng buộc
- Không đổi tên nhánh. Làm việc trên `arena/b37b6115-robloxstudio-connecting`, không tạo nhánh khác.
- Không merge hay đóng PR khi chưa được yêu cầu rõ.
- Không xoá file người dùng, không đụng `src/` ngoài phần đóng gói.
- Trước khi commit, chạy `git rev-parse HEAD`. Nếu HEAD không khớp `origin/arena/b37b6115-robloxstudio-connecting`, chạy `git fetch origin` rồi `git reset --mixed origin/arena/b37b6115-robloxstudio-connecting` (không `--hard`).
- Nếu lệnh `git` hoặc `gh` báo lỗi xác thực, dừng và báo người dùng kết nối lại GitHub. Không hỏi mật khẩu hay token.

## 5. Nghiệm thu
- `node bridge/publish.mjs --dry-run "test"` in đúng số file và dòng Command Bar, không đổi repo.
- `node tools/sync_sim/check_bundle.cjs` PASS sau khi publish thật.
- Một gói publish thật có SHA mới, và dòng Command Bar của nó tải được `plugin/StudioLiveBridge.server.luau` (kiểm bằng `curl -sI` cho URL raw).
- `agents/notes/SYNC_ARCHITECTURE.md` có sơ đồ, bảng file và danh sách bất biến.
- Báo cáo ngắn: đã đổi gì, đã kiểm gì, còn gì chưa làm.

## 6. Báo cáo
Trả về: (a) danh sách file đã đổi; (b) kết quả từng mục nghiệm thu; (c) rủi ro còn lại; (d) việc cần người dùng làm trong Studio (nếu có).
