# RobloxStudio-connecting

Dự án **Roblox Luau** được cấu hình sẵn với **Rojo v7.7.1**, hỗ trợ đồng bộ code trực tiếp giữa GitHub / trình soạn thảo code (VS Code, Cursor...) và **Roblox Studio**.

---

## Cấu trúc thư mục

| Thư mục / File trên Git | Ánh xạ trong Roblox Studio (`DataModel`) | Mô tả |
| :--- | :--- | :--- |
| `src/server/` | `ServerScriptService.Server` | Code chạy phía **Server** (`.server.luau`, ModuleScript...) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | Code chạy phía **Client** (`.client.luau`, UI controller...) |
| `src/shared/` | `ReplicatedStorage.Shared` | Module dùng chung cho cả Server và Client (`.luau`) |
| `default.project.json` | Cấu hình cây `DataModel` | File cấu hình chính của Rojo |
| `rokit.toml` | Quản lý phiên bản công cụ | Tự động cài đúng phiên bản `rojo`, `stylua`, `selene` |

### Quy ước đặt tên file trong Rojo (v7.7+)
- `*.server.luau` → Tạo thành **`Script`** (chạy trên Server)
- `*.client.luau` → Tạo thành **`LocalScript`** (chạy trên Client)
- `*.luau` → Tạo thành **`ModuleScript`**
- `init.server.luau` / `init.client.luau` / `init.luau` → Biến chính thư mục chứa nó thành `Script` / `LocalScript` / `ModuleScript`.

---

## Hướng dẫn kết nối vào Roblox Studio trên máy của bạn

### Bước 1: Clone repo về máy tính
```bash
git clone https://github.com/khungdienchinhhieu-cmd/RobloxStudio-connecting.git
cd RobloxStudio-connecting
```

### Bước 2: Cài đặt Rojo (chọn 1 trong 2 cách)

#### Cách A — Dùng Extension trên VS Code / Cursor (Nhanh nhất)
1. Mở thư mục `RobloxStudio-connecting` bằng **VS Code** hoặc **Cursor**.
2. Cài extension chính thức **Rojo - Roblox Studio Sync** (`evaera.vscode-rojo`).
3. Nhấn tổ hợp `Ctrl + Shift + P` (hoặc `Cmd + Shift + P` trên macOS) → chọn **`Rojo: Open Menu`**.
4. Nhấn nút **Install Roblox Studio Plugin** (nếu máy bạn chưa cài plugin Rojo cho Studio), sau đó nhấn **Start (`default.project.json`)**.

#### Cách B — Dùng dòng lệnh với Rokit CLI
1. Cài đặt [Rokit](https://github.com/rojo-rbx/rokit) rồi chạy lệnh sau trong thư mục dự án:
   ```bash
   rokit install
   ```
2. Cài plugin Rojo vào Roblox Studio (chỉ cần chạy 1 lần đầu):
   ```bash
   rojo plugin install
   ```
3. Khởi chạy server đồng bộ trực tiếp:
   ```bash
   rojo serve
   ```
   *(Hoặc nếu muốn xuất ra file `.rbxlx` để mở thẳng bằng Roblox Studio)*:
   ```bash
   rojo build -o "RobloxStudio-connecting.rbxlx"
   ```

### Bước 3: Kết nối trong Roblox Studio
1. Mở **Roblox Studio** (tạo một *Baseplate* mới hoặc mở place của bạn).
2. Vào tab **Plugins** → nhấn biểu tượng **Rojo** → bấm **Connect** (mặc định `localhost:34872`).
3. Nhấn **Play (F5)** và kiểm tra cửa sổ **Output** — nếu thấy 2 dòng thông báo từ `Server` và `Client` là bạn đã kết nối thành công!

---

## Kết hợp với Roblox Studio MCP (Tuỳ chọn)
Nếu bạn muốn AI Client trên máy cá nhân (Cursor, Claude Code, VS Code...) vừa sửa file trong repo Rojo này vừa điều khiển Playtest / kiểm tra Instance trực tiếp trong Studio:
1. Mở Roblox Studio → **Assistant** → **`…`** → **Manage MCP Servers**.
2. Bật **Enable Studio as MCP server** và bật công cụ bạn đang dùng trong mục **Quick connect**.
