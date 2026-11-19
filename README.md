# 🌊 YokaHub — King Legacy Modular Framework & Multi-Sea Suite

Hệ thống mã nguồn mở dạng module (Modular Architecture) dành riêng cho nhóm phát triển **YokaHub King Legacy**.

---

## 🗂️ CẤU TRÚC DỰ ÁN (15 MODULES CHUYÊN BIỆT)

Dự án được chia tách thành **15 tệp độc lập** theo trách nhiệm đơn lẻ, giúp các thành viên trong nhóm có thể code song song mà không bao giờ bị conflict:

```
YokaHub_Project/
├── .gitignore
├── README.md
├── CONTRIBUTING.md
├── dist/
│   └── YokaHub.luau                 # Bản build hoàn chỉnh được gộp tự động
├── tools/
│   ├── build.py                     # Trình gộp mã nguồn 1-click & đồng bộ Gist
│   ├── bracket_checker.py           # Bộ kiểm tra cân bằng dấu ngoặc
│   ├── keyword_checker.py           # Bộ kiểm tra cú pháp khối Luau
│   └── sync_gist.py                 # Tự động đẩy bản cập nhật lên GitHub Gist
└── src/
    ├── core/
    │   ├── 01_header.luau           # Khai báo môi trường, kiểu dữ liệu, Services
    │   ├── 03_config_state.luau     # Bộ lưu trữ HubState, đọc/ghi file cấu hình JSON
    │   └── 15_loops_engine.luau     # Luồng nền chạy ngầm (Anti-AFK, Auto Hop, Săn Boss, Câu Cá...)
    ├── security/
    │   └── 02_gateway.luau          # Cổng xác thực Key Salted SHA-256 (Free & Sponsor VIP)
    ├── ui/
    │   └── 04_luna_window.luau      # Cửa sổ Luna UI, Avatar nổi kéo thả, Dynamic Responsive
    └── modules/
        ├── 05_tab1_sea_boss.luau    # 🌊 TAB 1: Săn Boss Biển (Sea 3, Sea 2, Boss Đảo, Hop Server)
        ├── 06_tab2_farm_mobs.luau   # 🌾 TAB 2: Cày Cấp & Quái (Level 1-Max, Select Mob, Daily Quests)
        ├── 07_tab3_combat_skills.luau # ⚔️ TAB 3: Xả Chiêu & Haki (Trái, Kiếm, Melee, Aimbot, Dodge)
        ├── 08_tab4_materials.luau   # 📦 TAB 4: Gom Nguyên Liệu (Sea 3, Sea 2, Sea 1, Quantity Queue)
        ├── 09_tab5_dungeon.luau     # 🏰 TAB 5: Vượt Phó Bản (Easy/Normal/Hard, 3 Modes, Scepter Heal)
        ├── 10_tab6_fishing.luau     # 🎣 TAB 6: Câu Cá Tự Động (Chọn Cần/Kiếm, Nổi Mặt Nước, Thu Rương)
        ├── 11_tab7_fruits_shop.luau # 🍎 TAB 7: Trái & Cửa Hàng (Nhặt Trái, Cất Rương, Shop Sniper)
        ├── 12_tab8_esp_analytics.luau # 👁️ TAB 8: ESP & Thống Kê (ESP Radar, Session Tracker, Damage Meter, Webhook)
        ├── 13_tab9_optimization_utils.luau # ⚡ TAB 9: Tối Ưu & Tiện Ích (Xóa VFX, Giảm Lag, Anti-AFK 20p, Auto Play, Fast Move)
        └── 14_tab10_donate_exit.luau # 💖 TAB 10: Quyên Góp & Thoát (Donate QR, Tri Ân VIP, Exit An Toàn)
```

---

## 🚀 QUY TRÌNH BIÊN DỊCH VÀ CỘNG TÁC NHÓM

1. **Chỉnh sửa tính năng:** Các thành viên chỉ cần mở đúng tệp module trong `src/modules/` tương ứng để thêm/sửa code.
2. **Đóng gói 1-Click:**
   ```bash
   python tools/build.py
   ```
3. **Đóng gói & Đẩy lên Cloud Gist:**
   ```bash
   python tools/build.py --sync
   ```
