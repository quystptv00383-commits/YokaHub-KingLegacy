# 🚀 CẨM NANG PHÁT TRIỂN & CỘNG TÁC DỰ ÁN YOKAHUB

Chào mừng các thành viên trong đội ngũ phát triển YokaHub! 
Tài liệu này hướng dẫn chi tiết quy trình làm việc nhóm, cách phân chia module, quy tắc đóng góp và cách sử dụng công cụ biên dịch tự động 1-click.

---

## 📁 1. CẤU TRÚC THƯ MỤC MODULAR CHUẨN HOÁ

Dự án được phân rã thành các thư mục độc lập để tránh xung đột mã nguồn:

```text
YokaHub_Project/
├── .gitignore                      # Chặn các file bảo mật, token đẩy lên GitHub
├── README.md                       # Hướng dẫn làm việc chung cho cả nhóm
├── CONTRIBUTING.md                 # Quy chuẩn viết code & gửi Pull Request
├── dist/                           # Thư mục chứa file đóng gói hoàn thiện
│   └── YokaHub.luau
├── src/                            # Toàn bộ mã nguồn chia theo từng mảng
│   ├── core/                       # Cấu hình lõi & Vòng lặp chính
│   │   ├── 01_header.luau          # Khai báo thông tin phiên bản
│   │   ├── 03_config_state.luau    # Lưu/đọc trạng thái & tự gỡ lỗi 773
│   │   └── 11_loops_engine.luau    # Vòng lặp Auto Hop & Auto Fish
│   ├── security/                   # Hệ thống bản quyền (Chỉ Leader chỉnh sửa)
│   │   └── 02_gateway.luau         # Xác minh License Salted SHA-256
│   ├── ui/                         # Giao diện tổng thể
│   │   └── 04_luna_window.luau     # Cửa sổ Luna & Nút Avatar nổi
│   └── modules/                    # Các tính năng riêng lẻ (Thành viên làm việc tại đây)
│       ├── 05_tab1_bosshop.luau    # Tab Săn Boss (Sea 3, Sea 2, Solo F7)
│       ├── 06_tab2_farm.luau       # Tab Auto Farm, Xả Skill, Nguyên liệu, Dungeon, Câu cá
│       ├── 07_tab3_fruits.luau     # Tab Trái Ác Quỷ, Bắn tỉa Shop, Nhặt trái, ESP
│       ├── 08_tab4_metrics.luau    # Tab Thống kê Gems/Beli, Đo Damage, Nhật ký Drop
│       ├── 09_tab5_utility.luau    # Tab Chuyển Sea, Màn hình đen, Đồng minh, Webhook
│       └── 10_tab6_donate_exit.luau# Tab Ủng hộ Donate SePay & Đăng xuất Key
└── tools/                          # Bộ công cụ tự động hóa
    ├── build.py                    # Trình biên dịch & đóng gói 1-click
    ├── bracket_checker.py          # Kiểm tra tự động tính cân bằng ngoặc
    ├── keyword_checker.py          # Kiểm tra tự động tính cân bằng khối lệnh Luau
    └── sync_gist.py                # Tự động đẩy file cập nhật lên đám mây Cloud
```

---

## 👥 2. PHÂN CHIA VAI TRÒ TRONG ĐỘI NGŨ

| Vai Trò | Người Phụ Trách | Trách Nhiệm Chính |
| :--- | :--- | :--- |
| **Trưởng Nhóm (Project Lead)** | Yoka (Shinene_11) | Nắm giữ kho lưu trữ GitHub, quản lý hệ thống Key & Salt bản quyền (`02_gateway.luau`), duyệt các Pull Request và phát hành bản cập nhật chính thức. |
| **Lập trình viên Tính năng (Feature Devs)** | Thành viên A, B... | Đảm nhận các module cụ thể trong thư mục `src/modules/` (ví dụ: làm riêng Tab Câu Cá, Tab Dungeon, hoặc tối ưu Tab Săn Boss). Tuyệt đối không chỉnh sửa file của người khác. |
| **Thiết kế Giao diện (UI Dev)** | Thành viên C | Tùy chỉnh màu sắc, hoạt ảnh bo tròn, biểu tượng Material Icon trong `src/ui/04_luna_window.luau`. |
| **Kiểm thử viên (Tester / QA)** | Đội ngũ Test | Kiểm tra tính năng mới trên tài khoản phụ, ghi nhận lỗi phát sinh trước khi phát hành cho người dùng. |

---

## 🛠️ 3. QUY TRÌNH PHỐI HỢP LÀM VIỆC (GIT WORKFLOW)

Mỗi thành viên khi nhận một nhiệm vụ mới cần tuân thủ 5 bước chuẩn sau:

1. **Lấy mã nguồn mới nhất về máy**:
   * Trước khi làm việc, luôn đồng bộ từ nhánh chính (`main`) để đảm bảo không bị lỗi thời.
2. **Tạo nhánh tính năng riêng**:
   * Không bao giờ sửa trực tiếp trên nhánh `main`.
   * Đặt tên nhánh rõ ràng: ví dụ `feature-dungeon-upgrade`, `fix-fishing-rod`...
3. **Chỉnh sửa đúng file module được phân công**:
   * Nếu làm về Câu cá hoặc Dungeon, chỉ mở `06_tab2_farm.luau`.
   * Nếu làm về Bắn tỉa trái, chỉ mở `07_tab3_fruits.luau`.
4. **Biên dịch và kiểm tra cú pháp trên máy cá nhân**:
   * Chạy công cụ: `python tools/build.py`
   * Nếu bảng thông báo hiển thị `BUILD SUCCESSFUL` với 0 lỗi ngoặc và 0 lỗi khối điều khiển thì mới đạt yêu cầu.
5. **Gửi yêu cầu gộp mã (Pull Request - PR)**:
   * Đẩy nhánh lên GitHub và tạo một Pull Request mô tả chi tiết: tính năng vừa thêm là gì, đã kiểm tra như thế nào.
   * Chờ Trưởng nhóm duyệt và gộp vào nhánh chính.

---

## ⚡ 4. LỆNH BIÊN DỊCH VÀ XUẤT BẢN TỰ ĐỘNG

* **Biên dịch nội bộ để kiểm tra trên máy**:
  * Chạy file: `python tools/build.py`
  * Hệ thống sẽ tự động ghép các module, kiểm tra cú pháp và triển khai vào thư mục game trên máy để bạn vào game thử nghiệm ngay.
* **Biên dịch và phát hành trực tiếp lên Cloud (Dành cho Trưởng nhóm)**:
  * Chạy file: `python tools/build.py --sync`
  * Hệ thống sẽ kiểm tra bảo mật, đóng gói và tự động đẩy phiên bản mới lên GitHub Gist Cloud cho toàn bộ người dùng.

---

## 🔐 5. NGUYÊN TẮC BẢO MẬT BẮT BUỘC
* **Tuyệt đối không lưu mật khẩu, Private Salt hay Token webhook công khai** trong các module.
* Bất kỳ tính năng mới nào liên quan đến mạng (Http) đều phải bọc qua hàm gọi an toàn (`pcall`) để tránh làm văng script của người chơi.
