# GTA V (Los Santos) so với dự án của mình — bản nháp nghiên cứu

Người viết: Agent Chính · Trạng thái: nháp, để Agent 2 bổ sung · Bản sync tham chiếu: v29 (`66d6b20`)

## 1. GTA V làm gì (đã kiểm nguồn)

| Hạng mục | GTA V | Nguồn |
|---|---|---|
| Quy mô | Bản đồ 49 dặm vuông, lớn hơn mọi thế giới trước đó của Rockstar cộng lại | [New Yorker](https://www.newyorker.com/culture/culture-desk/idling-in-los-santos), [Wikipedia](https://en.wikipedia.org/wiki/Development_of_Grand_Theft_Auto_V) |
| NPC có lịch sinh hoạt | Hệ thống lập lịch người và xe theo giờ trong ngày | [Fandom: Features in GTA V](https://rockstargames.fandom.com/wiki/Features_in_Grand_Theft_Auto_V) |
| Phản ứng với người chơi | NPC chạy khi có súng, đi nhanh hơn khi bị rình, dùng điện thoại | [GameRant](https://gamerant.com/grand-theft-auto-5-small-details-enhance-open-world/), [Medium/AI behaviours](https://medium.com/@whosfinch/los-santos-by-foot-how-walkable-is-grand-theft-auto-5-646195f174da) |
| Giao thông | Xe đi đúng làn, dừng đèn đỏ, đổi làn, né tai nạn | [GameRant](https://gamerant.com/grand-theft-auto-5-small-details-enhance-open-world/), [Medium](https://medium.com/@dblaxDev/grand-theft-auto-v-as-a-landmark-of-open-world-design-3326a083c4a0) |
| Xe theo khu | Xe sang ở Vinewood/Rockford Hills, xe cũ ở khu nghèo | [Medium](https://medium.com/@dblaxDev/grand-theft-auto-v-as-a-landmark-of-open-world-design-3326a083c4a0) |
| Sự kiện ngẫu nhiên | 57 kịch bản (+3 bản next-gen), hiện chấm xanh/đỏ trên radar | [Medium/AI](https://medium.com/@whosfinch/los-santos-by-foot-how-walkable-is-grand-theft-auto-5-646195f174da) (bài tổng hợp, cần xác minh thêm) |
| Người đi bộ | Sinh ra gần người chơi rồi xoá khi đi xa (giới hạn bộ nhớ) | [Arqade](https://gaming.stackexchange.com/questions/131253/grand-theft-auto-5-los-santos-civilian-population) (nguồn cộng đồng) |
| Nội thất | Khoảng 40 toà nhà vào được, phần còn lại chỉ là phông | [ScreenRant](https://screenrant.com/gta-5-interiors-missing-empty-open-world-rockstar/) (ước tính cộng đồng) |
| Phá huỷ | Không có nhà phá huỷ được. Tương tác chủ yếu là xe, súng, người | Quan sát chung, không có nguồn riêng |
| Đồ hoạ | RAGE engine, draw distance lớn, chi tiết xa | [Bài đánh giá](https://hacker9.com/gta-v-game-review-why-it-still-dominates-the-open-world-genre/) |

**Điểm yếu GTA V đáng tránh:** đường xá chiếm phần lớn diện tích, nội thất gần như không có,
người đi bộ không thật, giao thông kém an toàn. Đây cũng là điều người chơi phàn nàn.

## 2. Dự án của mình đang có gì (đã kiểm trong repo)

| Hạng mục | Trạng thái | Bằng chứng |
|---|---|---|
| Thành phố | 10/10 ô đất, 11 module, ~26 014 BasePart | `agents/reviews/city-map-v27.png` |
| Phá huỷ | Có. D1 có 3 152 khối phá được | QA D1 9,1/10 |
| NPC | 93 NPC sống, 85/93 đã di chuyển > 8 stud | `node tools/npc_sim/run.cjs` → PASS |
| Quầy dịch vụ | 15 quầy, mỗi toà có chức năng | `counter_check.cjs` 15/15 |
| Tỉ lệ thật | 1:1, STUDS_PER_METER = 3.33 | `WorldGrid.meters()` |
| Giao thông | Có xe và lái xe NPC, chưa rõ đúng làn đèn đỏ | cần kiểm |
| Sự kiện ngẫu nhiên | Chưa có | — |
| Nội thất vào được | Cần kiểm: cửa có, nhưng chưa đếm được toà nào vào được thật | — |
| Lỗi nhà biến mất rồi hiện lại | Đang mở, do Agent Chính báo | Ảnh chụp trong Studio |

## 3. Khoảng cách và việc đề xuất (nháp)

1. **Nội thất:** kiểm xem bao nhiêu toà đi vào được. Mục tiêu: ít nhất các quầy dịch vụ.
2. **Sự kiện ngẫu nhiên:** thêm 3–5 sự kiện nhỏ, hiện dấu trên HUD. Chưa có nguồn chắc
   nên phải xác minh số liệu trước khi dùng.
3. **Giao thông:** kiểm đèn đỏ và đúng làn. Nếu chưa đúng thì sửa trước khi thêm xe mới.
4. **Lỗi nhà biến mất:** nghi do `CityCuller`. Cần đo khoảng cách bật/tắt rồi sửa.
5. **Giao diện:** thu nhỏ thẻ khu vực, để màn hình thoáng hơn.

## 4. Việc Agent 2 có thể nhận

- Kiểm nội thất: đếm toà vào được và ghi vào bảng ở mục 2.
- Điều tra `CityCuller` với lỗi nhà biến mất. Báo cáo theo đúng 5 mục trong prompt.
- Bổ sung nguồn cho mục 1, đặc biệt số liệu sự kiện ngẫu nhiên.
