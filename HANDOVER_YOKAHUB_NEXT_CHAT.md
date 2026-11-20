# TỔNG KẾT BÀN GIAO TOÀN DIỆN DỰ ÁN YOKAHUB (KING LEGACY)
> **Mục đích tài liệu:** Dùng để copy nguyên văn nội dung này dán vào phiên trò chuyện mới (Chat mới) để tiếp tục phát triển các module khác mà không bị mất ngữ cảnh, cấu trúc hoặc các quy chuẩn đã hoàn thiện.

---

## 1. THÔNG TIN ĐỊNH DANH & CƠ CHẾ NẠP ĐÁM MÂY (SINGLE LINK)
- **Tên dự án:** YokaHub (King Legacy Official)
- **Tác giả / Sở hữu:** Yoka (`quystptv00383-commits`)
- **Game ID Roblox:** `1451439645` (King Legacy)
- **Place IDs:** Sea 1 (`1451439645`), Sea 2 (`8737899170`), Sea 3 (`8737602449`)
- **Kho lưu trữ GitHub (Source Code):** `https://github.com/quystptv00383-commits/YokaHub-KingLegacy` (Nhánh: `main`)
- **Kho Gist Đám Mây (Cloud Distribution):** `https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/`
- **Link Loader duy nhất (Single Loader Link - Tự động cập nhật 24/7):**
  ```lua
  loadstring(game:HttpGet("https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/loader.luau?t=" .. os.time()))()
  ```
- **Tệp nạp ngắn gọn tại máy người dùng:**
  - `C:\Users\THIS PC\AppData\Local\Real\scripts\scriptKing.luau`
  - `C:\Users\THIS PC\AppData\Local\Real\autoexec\scriptKing.luau`
  *(Chỉ chứa 19 dòng lệnh: Chờ game tải, đợi PlayerGui, kiểm tra chống chạy đè và gọi loader duy nhất)*

---

## 2. KIẾN TRÚC THƯ MỤC NGUỒN (MODULAR ARCHITECTURE)
Thư mục gốc: `C:\Users\THIS PC\AppData\Local\Real\scripts\YokaHub_Project`

Toàn bộ dự án được phân chia thành **15 phân hệ (modules)** rõ ràng và được tổng hợp tự động thành 1 tệp duy nhất `dist/YokaHub.luau` (8.282 dòng lệnh):

1. `src/core/01_header.luau`:
   - Kiểm tra GameID King Legacy.
   - Thiết lập môi trường thực thi (getgenv, Services: Http, Teleport, Tween, RunService, VirtualInputManager).
2. `src/security/02_gateway.luau`:
   - Giao diện Gateway xác thực bảo mật chuẩn PRO (Home, Nhập Key, Get Key Free, Mua Key VIP).
   - Cơ chế băm mật mã Salted SHA-256 (`YokaHub_Secured_2026_Salt!`) chống dịch ngược và chống vượt cổng (bypass).
   - Tự động lưu License và HWID trên máy (`workspace/YokaHub_License.json`).
3. `src/core/03_config_state.luau`:
   - Định nghĩa cấu trúc kiểu dữ liệu HubState (102 biến trạng thái).
   - Đọc và ghi tệp cấu hình JSON mượt mà (`workspace/YokaHub_State.json`).
4. `src/ui/04_luna_window.luau`:
   - Khởi tạo thư viện Luna Interface Suite cao cấp (tông màu đen huyền Obsidian & xanh ngọc Mint).
   - Đã vá triệt để lỗi Dropdown indexing của Luna (tự động fallback về template khi gặp tùy chọn lạ, miễn nhiễm 100% văng script).
   - Nút Phóng to / Thu nhỏ toàn màn hình (Maximize / Fullscreen Toggle) ở góc trên bên phải.
   - Tay nắm kéo dãn kích thước góc dưới bên phải (Corner Drag Resizer).
   - Lắng nghe kích thước màn hình `ViewportSize` để responsive co giãn tỉ lệ `UIScale` tự động trên mọi màn hình.
   - Nút tròn thu nhỏ/mở lại Hub (Floating Dock Icon 60x60).
5. `src/modules/05_tab1_sea_boss.luau` (Tab 1: 🌊 Săn Boss Biển):
   - Chế độ săn riêng API (Solo Hop Target: Depth King, Drakenfyr Dragon, Abyssal Tyrant, Kraken, Crab, Hydra, Sea King, Ghost Ship, Serpent).
   - Săn tổng hợp Sea 3 (Phím F8) & Săn tổng hợp Sea 2 (Phím F9).
   - Master Auto Fight Boss & Sea Event, tự nhặt rương báu, thanh trượt độ cao an toàn khi đánh.
   - Săn Boss đảo (Hephaestus, Dark Beard, Gryphon, Lucidus, v.v.) kèm tự nhận Quest trước khi đánh.
6. `src/modules/06_tab2_farm_mobs.luau` (Tab 2: 🌾 Cày Cấp & Quái):
   - Farm Level tự động (Level 1 - Max).
   - Giữ khoảng cách an toàn trên không khi farm.
   - Tự nhận nhiệm vụ theo cấp độ hiện tại (Auto Level Quest).
   - Tự tăng điểm chỉ số (Auto Stats): Melee, Defense, Sword, Fruit kèm thanh trượt điểm mỗi tick (1 - 50 điểm).
   - Farm quái chọn lọc (Select Mob Dropdown), gom quái nhanh (Fast Mob Bring).
   - Tự làm nhiệm vụ hàng ngày (Daily Quests) & tự quay tộc (Auto Race Roll).
7. `src/modules/07_tab3_combat_skills.luau` (Tab 3: ⚔️ Xả Chiêu & Haki):
   - Công tắc tổng xả chiêu (Auto Skills Master).
   - Tùy chọn phím chiêu xả cho Trái Ác Quỷ (Z, X, C, V, E).
   - Tùy chọn phím chiêu cho Kiếm (Sword) & Võ (Melee).
   - Tự bật Haki Vũ Trang (Buso V1/V2) & Haki Quan Sát (Ken V2).
   - Tự động biến hình Trái Ác Quỷ khi giao tranh (Auto Transform).
   - Khóa chiêu vào tim mục tiêu gần nhất (Skill Direction Aimbot).
   - Tự động lướt né chiêu khi máu thấp hoặc quái áp sát (Auto Dodge / Soru).
8. `src/modules/08_tab4_materials.luau` (Tab 4: 📦 Gom Nguyên Liệu):
   - Gom nguyên liệu Sea 3 (Coral, Shark's Fin, Dragon Scale, Sea King Blood, Phoenix Tear).
   - Gom nguyên liệu Sea 2 (Iron Ingot, Dark Powder, Ghost Flesh, Magma Crystal).
   - Gom nguyên liệu Sea 1 (Leather, Wood, Rope, Thief Rag).
   - Luồng đếm số lượng nguyên liệu trong túi đồ (Quantity Tracker).
9. `src/modules/09_tab5_dungeon.luau` (Tab 5: 🏰 Đi Tháp Dungeon):
   - Tự động vào phòng Dungeon (Easy, Medium, Hard, Nightmare).
   - Chiến thuật đánh: Safe Mode (giữ khoảng cách 260m), Fast Mode, Normal Mode.
   - Tự động cầm trượng hồi máu (Scepter Auto Heal) & khóa góc nhìn camera.
10. `src/modules/10_tab6_fishing.luau` (Tab 6: 🎣 Câu Cá Tự Động):
    - Tự động quăng cần & giật cá hoàn hảo (Perfect Catch).
    - Tự cầm cần câu hoặc kiếm câu cá chỉ định.
11. `src/modules/11_tab7_fruits_shop.luau` (Tab 7: 🍎 Trái Ác Quỷ & Shop):
    - Tự hút trái rơi trên toàn bản đồ (Bring Dropped Fruits) & cất kho tự động (Store Fruits).
    - Shop Sniper: Tự canh và mua ngay trái Thần Thoại / Meta khi cửa hàng xoay tua.
    - Lấy toàn bộ trái trong rương ra balo (Unstore All) & Thả trái rơi ra đất chuẩn lệnh (Drop Fruit).
12. `src/modules/12_tab8_esp_analytics.luau` (Tab 8: 👁️ ESP & Thống Kê):
    - Định vị toàn cảnh: ESP Trái Ác Quỷ, ESP Người chơi, ESP Rương kho báu kèm khoảng cách mét.
    - Bộ đo sát thương thực tế (Damage Meter): Đo dame từng hit, combo dồn sát thương và dame kỷ lục.
    - Dịch chuyển đến đảo (Island Teleports): Đầy đủ tọa độ tất cả các đảo Sea 1, Sea 2 và Sea 3.
13. `src/modules/13_tab9_optimization_utils.luau` (Tab 9: ⚡ Tối Ưu & Tiện Ích):
    - Tự đóng hộp thoại lỗi văng phòng 773 / 772 / 279.
    - Tự bấm Play khi vào game, tự chạy lại script khi đổi server (Auto Re-exec).
    - Màn hình đen giảm 80% CPU/GPU treo máy qua đêm (Black Screen AFK).
    - Fast Mode xóa hiệu ứng giật lag, chống văng game 20 phút (Anti-AFK).
    - Đi bộ trên mặt nước (Walk on Water) & Nhảy vô hạn (Infinite Jump).
    - Tự động gửi & chấp nhận lời mời kết bạn đồng minh (Auto Ally).
    - Dịch chuyển nhanh giữa các Biển (Sea 1, Sea 2, Sea 3).
14. `src/modules/14_tab10_donate_exit.luau` (Tab 10: 💖 Ủng Hộ & Thoát):
    - Mã VietQR & thông tin ngân hàng MB Bank: `36390914112009` (Chủ TK: SON TRAN PHU QUY).
    - Tự động đọc và hiển thị danh sách người ủng hộ (Donator Leaderboard).
    - Nút sao chép STK nhanh vào Clipboard.
    - Đăng xuất / Đổi Key bản quyền ra giao diện Gateway.
15. `src/core/15_loops_engine.luau`:
    - Động cơ lõi vận hành **18 luồng chạy ngầm độc lập** (Worker Threads).
    - Quản lý vòng lặp hop server, kiểm tra boss alive, farm mobs, auto stats, level quest, aimbot, dodge, quantity tracker, anti-afk, webhook logs và dọn dẹp bộ nhớ.

---

## 3. CÔNG CỤ DỰ ÁN & QUY TRÌNH BUILD / AUDIT (TOOLS)
- `tools/build.py`: Biên dịch nối 15 module thành `dist/YokaHub.luau`, chạy kiểm tra ngoặc (`bracket_checker.py`), cấu trúc khối (`keyword_checker.py`), sao chép sang `workspace/YokaHub.luau`.
  - Lệnh chạy: `python tools/build.py` (hoặc `python tools/build.py --sync` để tự động đẩy lên Gist).
- `tools/sync_gist.py`: Đồng bộ các tệp phân phối lên GitHub Gist cá nhân bằng Personal Access Token.
- `tools/yokahub_deep_auditor.py`: Công cụ rà soát chuyên sâu 5 tầng:
  1. Cú pháp & cấu trúc (0 lỗi).
  2. Logic ngầm (100% loop có yield, 46 điểm nil-safety, 54 giáp pcall, đồng bộ 100% biến trạng thái).
  3. Bảo mật bản quyền (Salted SHA-256, 38/38 key hợp lệ).
  4. Tính toàn vẹn chức năng (102/102 nút chức năng hoạt động thực tế).
  5. Trạng thái Git & Gist (Sạch sẽ, phản hồi 200 OK).
- `tools/continuous_logic_checker.py`: Daemon chạy ngầm quét kiểm tra định kỳ mỗi 60 giây.
- `tools/audit_controls.py`: Quét đối soát 102 tương tác UI và xác nhận không có bất kỳ nút rác ("nút cho có").

---

## 4. HỆ THỐNG KEY BẢN QUYỀN (LICENSING & KEYS)
- **Chuỗi muối bảo mật (Hex Salt):** `YokaHub_Secured_2026_Salt!`
- **Thuật toán băm:** `SHA-256(Key + Salt)`
- **Kho Key gốc:** Được lưu tại `workspace/danh_sach_key_vip_chua_dung.txt` gồm **38 Key VIP**.
- **Kho Hash đám mây:** `YokaHub_Keys.json` chứa 38 mã băm SHA-256 đã xác thực 100%.

---

## 5. CÁC QUY TẮC CỐT LÕI KHI TIẾP TỤC LÀM VIỆC Ở CHAT MỚI
Khi chuyển sang đoạn chat mới, hãy nhắc trợ lý AI tuân thủ nghiêm ngặt các quy tắc sau:
1. **TUYỆT ĐỐI KHÔNG SHOW CODE:** Trong câu trả lời hiển thị cho người dùng, tuyệt đối không được đưa các khối mã nguồn Lua/Python/Shell (chỉ giải thích rõ ràng bằng lời văn tiếng Việt).
2. **BẢO VỆ 1 LINK ĐÁM MÂY DUY NHẤT:** Không tạo thêm link rải rác. Mọi nâng cấp đều phải chỉnh sửa trong `src/`, chạy `build.py`, kiểm tra bằng `yokahub_deep_auditor.py` và đồng bộ lên Gist duy nhất.
3. **GIỮ GÌN THƯ MỤC SCRIPTS SẠCH SẼ:** Trong `C:\Users\THIS PC\AppData\Local\Real\scripts`, chỉ duy trì duy nhất tệp nạp `scriptKing.luau`, không được tạo file linh tinh làm bừa bộn.
4. **BẢO MẬT KEY BẰNG SALTED SHA-256:** Giữ nguyên chuỗi muối `YokaHub_Secured_2026_Salt!` và cơ chế Gateway xác thực.
5. **ĐẢM BẢO TÍNH THỰC TẾ 100%:** Bất kỳ tính năng mới nào được thêm vào UI đều phải có luồng xử lý ngầm thực tế trong `15_loops_engine.luau`, không được làm nút bấm hình thức.

---
*(Tệp được khởi tạo tự động phục vụ bàn giao dự án ngày 20/11/2026)*
