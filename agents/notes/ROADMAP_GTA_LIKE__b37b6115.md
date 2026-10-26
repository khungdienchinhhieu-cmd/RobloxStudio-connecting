# Lộ trình: biến dự án thành GTA V tương tự — Agent Chính × Agent 2

Cập nhật: 13:40 26/10 · Nhánh: arena/b37b6115 · Bản sync đang chạy: v29 (66d6b20)

## Tiêu chí "giống GTA V" (lấy từ GTA5_VS_LOS_SANTOS.md)
Ưu tiên theo cái người chơi cảm nhận đầu tiên:
1. **Thế giới sống:** NPC đi lại theo lịch, phản ứng khi thấy súng/xe, xe đúng làn và dừng đèn đỏ.
2. **Nội thất vào được:** đếm, rồi mở thêm tối thiểu các quầy dịch vụ.
3. **Sự kiện ngẫu nhiên:** 3–5 sự kiện nhỏ, có dấu trên HUD.
4. **Ổn định:** không nhà biến mất, không khựng khi di chuyển (CityCuller).
5. **Giao diện:** thu gọn thẻ khu vực, HUD không che nhân vật.

## Thứ tự thực hiện (đã chốt)
| # | Việc | Ai | Điều kiện nộp |
|---|---|---|---|
| 1 | AGENT_7 đèn đường/cọ/tín hiệu | Agent 2 (7137180e) | 0 cặp đè với 11 module, báo cáo đủ 5 mục |
| 2 | CityCuller: nhà biến mất khi đi gần | Agent 2 | Đo khoảng cách bật/tắt, không còn biến mất trong ảnh chụp |
| 3 | Đếm toà nhà vào được + mở quầy | Agent 2 | Bảng số liệu, ảnh nội thất |
| 4 | Sự kiện ngẫu nhiên (3–5) | Agent Chính | Có nguồn cho số liệu |
| 5 | Thu gọn UI thẻ khu vực | Agent Chính | Ảnh trước/sau |
| 6 | NPC giao thông đúng làn/đèn đỏ | Agent 2 (sau 3) | Harness giao thông |

## Quyết định đã chốt (ghi để không hỏi lại)
- **D2 (Maze Bank):** KHÔNG thay. Bản nộp của bc783dbc cũng có 90 cặp đè, không tốt hơn. Agent 4 phải sửa rồi nộp lại (xem QA note).
- **Tiêu chí nghiệm thu đè:** chỉ dùng `tools/building_sim/overlap_check.cjs Plot_X` (tên ô, không dùng đường dẫn).
- **Thứ tự:** 1 → 2 → 3 như bảng, không đảo.

## Đã biết nhưng chưa xử lý
- D2 đang chạy trên main có 90 cặp đè từ trước. Sẽ sửa khi Agent 4 nộp lại.
