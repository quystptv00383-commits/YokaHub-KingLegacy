# QUY CHUẨN ĐÓNG GÓP MÃ NGUỒN CHO ĐỘI NGŨ YOKAHUB

Để giữ cho dự án luôn gọn gàng, hiệu năng cao và không bị lỗi, các thành viên cần tuân thủ các quy tắc sau:

### 1. QUY TẮC VIẾT MÃ (CODING CONVENTIONS)
* Luôn bọc các tương tác nhạy cảm (RemoteEvents, Http, DataModel) trong khối bảo vệ `pcall`.
* Không sử dụng các biến toàn cục tùy tiện; ưu tiên khai báo `local` trong phạm vi module.
* Khi kết nối sự kiện lắng nghe (RBXScriptSignal), phải đảm bảo có cơ chế ngắt kết nối (Disconnect) khi đổi phòng hoặc đóng giao diện.
* Giữ nguyên cấu trúc giao diện theo tông màu Obsidian và Xanh Ngọc chuẩn của YokaHub.

### 2. QUY CHUẨN COMMIT MESSAGE
Khi lưu lịch sử mã nguồn (Git Commit), hãy đặt tên rõ ràng theo mẫu:
* `feat(fishing): bổ sung tự động chọn cần câu và quăng mồi`
* `fix(dungeon): sửa lỗi camera không khóa trúng boss ải 5`
* `ui(theme): căn chỉnh lại độ bo tròn của nút avatar nổi`
* `perf(hop): tối ưu thuật toán tìm phòng không tạo rác bộ nhớ`

### 3. KIỂM TRA BẮT BUỘC TRƯỚC KHI GỬI PULL REQUEST
Trước khi tạo PR, thành viên bắt buộc phải chạy lệnh:
`python tools/build.py`
Chỉ khi kết quả trả về `Bracket Check: PASSED (0 errors)` và `Keyword Balance Check: PASSED (0 errors)` thì yêu cầu mới được Trưởng nhóm xem xét và chấp thuận.
