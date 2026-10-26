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

---

## 5. Bổ sung (13:55 26/10): hệ thống truy nã và sự kiện ngẫu nhiên

### 5.1 Cấp truy nã (Wanted Level) — 5 sao, không phải 6
Nguồn: [GTA Wiki: Wanted Level](https://gta.fandom.com/wiki/Wanted_Level_in_GTA_V), [GTA Wiki (gta.wiki)](https://gta.wiki/w/Wanted_Level_in_GTA_V), [Kotaku](https://kotaku.com/the-mystery-of-gta-vs-six-star-wanted-level-1702882721)

- **1 sao:** tội nhẹ. Cảnh sát đuổi, dừng xe ép người chơi xuống (có thể bắt ngay). Bảo vệ tư nhân bắn ngay.
- **2 sao:** cảnh sát bắn không cần người chơi cầm súng. Ít nhất 3 xe cảnh sát đuổi. Chặn xe bằng xe tuần tra.
- **3 sao:** trực thăng tham gia. Bắn hạ cảnh sát nhảy thẳng lên 3 sao.
- **4–5 sao:** nhiều trực thăng, xe bọc thép, đặt chốt chặn đường (5 sao: gần như không có lối thoát).
- **Mất sao:** đi khỏi tầm nhìn của cảnh sát. Một vùng tìm kiếm đỏ hiện trên radar, nằm trong vùng đó thì bị tìm lại nhanh. Thời gian mất sao tăng theo số sao.

Điểm dùng được cho dự án: mô hình "tầm nhìn + vùng tìm kiếm + tăng dần theo mức" đơn giản hơn nhiều so với AI đầy đủ. Đây là tiêu chí nghiệm thu rõ ràng để thêm sau.

### 5.2 Sự kiện ngẫu nhiên (Random Events)
Nguồn: [GTA Wiki: Random Events](https://gta.fandom.com/wiki/Random_Events_in_GTA_V), [GTABase](https://www.gtabase.com/grand-theft-auto-v/side-missions/random-events)

- Bản gốc có **57** sự kiện (bản Enhanced có 60). Số liệu của các nguồn không khớp hoàn toàn, nên dùng con số "57 gốc".
- Hiện dưới dạng **chấm xanh trên radar** khi người chơi đi gần. Mỗi sự kiện chỉ xảy ra một lần, hoặc lặp lại tuỳ loại.
- Các loại tiêu biểu: **cướp ví** (đuổi kẻ cướp, trả ví hoặc giữ tiền), **cướp cửa hàng** (bắn đuổi kẻ cướp trước khi chúng lên xe), **cứu người bị hành hung trong hẻm**.
- Có **lựa chọn đạo đức**: giúp người bị hại hay giữ tiền. Đây là phần làm sự kiện có cảm giác "sống".

### 5.3 Đề xuất cho dự án (để Agent 2 và mình chốt)
- Sự kiện đầu tiên nên là **cướp ví**: một NPC bị giật ví, người chơi đuổi theo, trả hoặc giữ tiền. Chi phí thấp, dùng lại được NPC và xe hiện có.
- Truy nã đầu tiên: **chỉ 1 sao và 2 sao**, bắt đầu khi người chơi bắn hoặc đâm xe vào NPC trước mặt cảnh sát. Chưa làm trực thăng.
