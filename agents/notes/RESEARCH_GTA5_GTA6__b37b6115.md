# Nghiên cứu chi tiết: GTA V và GTA VI — để chúng ta tự làm (không dùng agent phụ)

Cập nhật: 26/10 · Chỉ ghi số liệu có nguồn. Phân loại: ✅ hãng xác nhận · 📰 báo chí dẫn lời phỏng vấn · ⚠️ tin đồn/suy đoán của fan, KHÔNG dùng để quyết định.

## 1. GTA VI — thông tin xác nhận
- ✅ Phát hành **19/11/2026**, PS5 và Xbox Series X|S. Không có PC ở thời điểm này. Nguồn: [Rockstar Games](https://www.rockstargames.com/newswire/article/ak3ak31a49a221/grand-theft-auto-vi-is-now-set-to-launch-november-19-2026), [Wikipedia](https://en.wikipedia.org/wiki/Grand_Theft_Auto_VI).
- ✅ Bối cảnh: bang **Leonida** (lấy cảm hứng Florida), gồm **Vice City** hiện đại. Hai nhân vật: Jason Duval và Lucia Caminos.
- 📰 **Vice City lớn gấp đôi Los Santos** và có gấp 11 lần số thị trấn nhỏ. Nguồn: lời Rob Nelson qua phỏng vấn, [WCCFtech](https://wccftech.com/roundup/gta-6-everything-we-know/).
- 📰 Chiến dịch có thể kéo dài tới **80 giờ**. Không có góc nhìn thứ nhất lúc ra mắt. Nguồn: cùng bài trên.
- 📰 Mật độ NPC và hoạt ảnh rất lớn: hơn **600 000 hoạt ảnh NPC** độc nhất, so với 300 000 ở RDR2 và 55 000 ở GTA V. Nguồn: [Wikipedia](https://en.wikipedia.org/wiki/Grand_Theft_Auto_VI) (trích số liệu, chưa có nguồn gốc từ hãng).
- ✅ Rockstar nói không có vi giao dịch và không có tính năng AI tạo sinh lúc ra mắt. Nguồn: tổng hợp trong [gtavicenews](https://gtavicenews.com/en/news/gta-6-release-date-everything-confirmed-so-far) (cần đối chiếu với nguồn gốc).

## 2. GTA VI — kỹ thuật (phân loại rõ)
- ✅/📰 Engine: **RAGE** (Rockstar Advanced Game Engine). Tên "RAGE 9" là **tên fan đặt**, Rockstar không công bố số phiên bản. Nguồn: [GTA6Hype](https://www.gta6hype.com/blog/rage9-vs-genie3-ai-future-gaming/).
- 📰 Trailer 2 được quay từ bản chơi thật trên PS5. Phân tích Digital Foundry: khoảng 1440p nâng lên 4K, **30 fps** trên console. Nguồn: [GTA6Hype](https://www.gta6hype.com/blog/rage9-vs-genie3-ai-future-gaming/), [gta6info](https://gta6info.com/pages/graphics.html) (đều dẫn Digital Foundry, cần xem bài gốc của DF để chắc chắn).
- 📰 Chiếu sáng: ray-traced global illumination theo phân tích Digital Foundry. Đây là điểm "trung bình chắc chắn" trong nhóm tin này.
- ⚠️ **Không dùng cho quyết định:** Euphoria 2.0 "hệ thần kinh trung ương", WaveWorks cho nước, "Dialogue Decay", "cấu trúc patent US 11,684,855" (trích từ site fan), "thuật toán phá huỷ theo mật độ vật liệu" (dựa trên tin tuyển dụng đã bị sửa). Không có nguồn chính thức nào trong nghiên cứu này xác nhận các mục đó.

## 3. GTA V — cơ chế thật (đã có nguồn nhiều bên)

### 3.1 Truy nã 5 sao
Đã có trong `GTA5_VS_LOS_SANTOS.md` mục 5.1. Bổ sung:
- Tầm nhìn: cảnh sát giữ đường thẳng nhìn thấy người chơi. Khi mất, vùng tìm kiếm đỏ hiện trên radar. Thời gian mất sao tăng theo số sao. Nguồn: [GTA Wiki](https://gta.wiki/w/Wanted_Level_in_GTA_V).
- Dispatch: GTA V có hệ thống điều phối (`dispatch.meta`) quyết định đơn vị nào xuất hiện ở mỗi mức sao. Nguồn: [GTAVillage](https://gtavillage.com/gta-5/tutorials/9351-wanted-level-customization-police-response-2026) (đây là bài hướng dẫn mod, không phải tài liệu chính thức).

### 3.2 Dân cư: spawn theo vùng và tái sử dụng
- Dân sinh ra gần người chơi, xoá khi đi xa, vì giới hạn bộ nhớ. Nguồn: [Arqade](https://gaming.stackexchange.com/questions/131253/grand-theft-auto-5-los-santos-civilian-population) (nguồn cộng đồng, nhưng khớp với cách nhiều game open-world làm).
- Mỗi NPC có **kho hội thoại** theo kiểu (archetype): cảnh sát, nam/nữ, độ tuổi. Nguồn: [Game Developer](https://www.gamedeveloper.com/design/breaking-down-gta-v-s-pedestrian-dialogue-system-an-analysis-with-speculative-examples) (phân tích, một phần là suy đoán có ghi rõ).
- Hội thoại ngắn kiểu "What?", "Unbelievable!" để tái sử dụng một câu thoại nhiều lần. Cùng nguồn.

### 3.3 Sự kiện ngẫu nhiên
Đã có trong `GTA5_VS_LOS_SANTOS.md` mục 5.2. Thêm: 57 sự kiện gốc, 60 bản Enhanced. Có loại lặp lại (cướp ví, cướp cửa hàng), có loại chỉ một lần. Nguồn: [GTA Wiki](https://gta.fandom.com/wiki/Random_Events_in_GTA_V), [GTABase](https://www.gtabase.com/grand-theft-auto-v/side-missions/random-events).

### 3.4 Giao thông
- Xe đi theo làn, dừng đèn đỏ, đổi làn, né tai nạn. Nguồn: [GameRant](https://gamerant.com/grand-theft-auto-5-small-details-enhance-open-world/).
- Xe và NPC hoạt động ở **tần số khác nhau**: người không cần cập nhật 30 lần/giây, chỉ vài "tác nhân gần camera" mới cần xử lý từng khung hình. Nguồn: [DEV Community](https://dev.to/saeedjt/gta-6-npc-technology-how-open-world-crowds-are-actually-simulated-43j8) (phân tích chung, không phải tài liệu Rockstar, nhưng là nguyên tắc kỹ thuật phổ biến).

## 4. Điều dự án của chúng ta có thể làm THẬT (ưu tiên theo chi phí)

| # | Tính năng | Lấy cảm hứng từ | Chi phí | Đo bằng gì |
|---|---|---|---|---|
| 1 | NPC đi theo làn + dừng đèn đỏ | GTA V giao thông | Trung bình | Harness giao thông (mới) |
| 2 | Cướp ví (sự kiện ngẫu nhiên #1) | GTA V random events | Thấp | Đếm sự kiện đã kích hoạt |
| 3 | Truy nã 1–2 sao, mất sao khi thoát tầm nhìn | GTA V wanted | Trung bình | Kịch bản: bắn NPC → sao tăng → thoát → sao giảm |
| 4 | Dân theo khu (xe sang Vinewood, xe cũ khu nghèo) | GTA V xe theo khu | Thấp | Đếm loại xe theo ô |
| 5 | Nội thất vào được cho quầy dịch vụ | GTA V (40 toà) | Trung bình | Đếm toà vào được |
| 6 | Giảm tần suất cập nhật NPC xa camera | Nguyên tắc tần số | Trung bình | FPS và số tác nhân cập nhật |

**Không làm:** nước mô phỏng vật lý, cơ thể mềm, hệ thần kinh NPC, AI nói chuyện. Lý do: không có nguồn xác nhận, và chi phí quá lớn so với lợi ích cho dự án này.

## 5. Việc tiếp theo (đề xuất, chờ chủ dự án duyệt)
1. Sửa `CityCuller` (đang là lỗi ảnh hưởng người chơi ngay). Sẽ tự làm vì không còn agent phụ.
2. Cướp ví (mục 4 số 2).
3. Đo và sửa giao thông (mục 4 số 1) bằng một harness mới.
