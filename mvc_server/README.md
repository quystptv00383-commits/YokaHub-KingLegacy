# YokaHub MVC Server & SQL Server Integration

Hệ thống Backend MVC cục bộ kết nối trực tiếp với **Microsoft SQL Server (`MSSQLSERVER`)** trên máy tính của bạn, đồng bộ dữ liệu Boss Live, Drop Logs, Phiên Farm, Cấu hình Tab và License Keys giữa Roblox Client (`YokaHub`) và SSMS.

## Cấu trúc mô hình MVC
- **`database/schema.sql`**: Khởi tạo database `YokaHubDB` và 5 bảng chuẩn (`BossServers`, `DropLogs`, `HunterSessions`, `HubConfigs`, `LicenseKeys`).
- **`models/` (Model)**:
  - `db_connection.py`: Quản lý kết nối `pyodbc` tới SQL Server (ODBC Driver 18/17, Windows Authentication) và tự động tạo schema khi khởi động.
  - `boss_model.py`: Truy vấn/cập nhật `dbo.BossServers`, tự động dọn phòng hết hạn sau 90 giây.
  - `analytics_model.py`: Lưu lịch sử drop, thống kê phiên treo, đồng bộ cấu hình và import hash key từ `YokaHub_Keys.json`.
- **`controllers/` (Controller)**:
  - `boss_controller.py`: Xử lý `/api/bosses`, `/api/report` và tự động bắn thẻ `🔥 BOSS DETECTED` sang Discord Webhook khi có phòng Boss mới.
  - `analytics_controller.py`: Xử lý `/api/drops`, `/api/session`, `/api/config`, `/api/health`, `/api/dashboard`.
  - `view_controller.py`: Nạp dữ liệu từ Model vào template HTML View.
- **`views/` (View)**:
  - `dashboard.html`: Giao diện Web Dashboard trực quan tại `http://127.0.0.1:8787`.
- **`app.py`**: Front Controller khởi chạy server đa luồng tại `127.0.0.1:8787`.

## Cách khởi chạy
Chạy lệnh từ thư mục `YokaHub_Project`:
`python mvc_server/app.py`

Sau khi chạy, mở trình duyệt vào `http://127.0.0.1:8787` hoặc mở **SQL Server Management Studio (SSMS)** kết nối `localhost` sẽ thấy database **`YokaHubDB`** cùng đầy đủ các bảng và dữ liệu đồng bộ trực tiếp từ YokaHub.
