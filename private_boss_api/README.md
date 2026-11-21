# YokaHub Private Boss API (Cloudflare Worker — Miễn Phí)

Thư mục này chứa mẫu API riêng cho YokaHub để tổng hợp danh sách phòng có Boss (`Depth King`, `Dragon`, `Abyssal Tyrant`, `Hydra`, `Sea King`, ...) từ các client YokaHub hoặc bot quét.

## Cách triển khai nhanh (5 phút trên Cloudflare)
1. Đăng nhập Cloudflare Dashboard -> **Workers & Pages** -> **Create Worker**.
2. Dán nội dung file `worker.js` vào trình soạn thảo Worker rồi bấm **Deploy**.
3. Tạo KV Namespace tên `yoka-boss-kv` trong **Storage & Databases -> KV**, rồi vào **Worker Settings -> Variables and Secrets / Bindings** gán KV Binding tên **`BOSS_KV`**.
4. (Tùy chọn bảo mật & Discord Boss Live) Trong **Worker Settings -> Variables and Secrets**:
   - Thêm Secret **`YOKA_API_KEY`** nếu muốn chỉ các client nhập đúng key mới đọc/gửi báo cáo được.
   - Thêm Secret **`DISCORD_WEBHOOK_URL`** nếu muốn Worker tự động bắn thông báo Boss sống (`EventName`, `% HP`, `Players`, `JobId`) về kênh Discord Boss API mỗi khi có phòng Boss mới xuất hiện.
5. Copy URL Worker (dạng `https://yoka-boss-api.ten-cua-ban.workers.dev`) dán vào ô **YokaHub Private Boss API URL** trong **Tab 1** của YokaHub.
