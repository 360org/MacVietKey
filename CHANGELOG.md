# MacVietKey Change Log

##### Version 2.2.0: (20/11/2026) — Bản phát hành chính thức MacVietKey (VuaOffice Suite)
- **Watchdog tự phục hồi EventTap:** Tích hợp bộ giám sát ngầm chu kỳ 1.0 giây từ EVKey, tự kích hoạt lại hook bàn phím khi macOS ngắt luồng.
- **Tối ưu Zero-IPC:** Loại bỏ quét cửa sổ `CGWindowListCopyWindowInfo` trên từng phím gõ, triệt tiêu độ trễ phím trên Spotlight, Chrome và Safari.
- **Sửa dứt điểm lỗi mất quyền Trợ năng khi tắt mở máy:** Nhúng Designated Requirement cố định `com.vuahethong.vuaoffice.macvietkey` vào chữ ký số và thêm vòng lặp chờ khởi động.
- **Cập nhật biểu tượng chính thức:** Tích hợp bộ `Icon.icns` 10 tầng chuẩn Apple (xanh công nghệ kèm phím ⌘), sửa dứt điểm icon chữ V đỏ cũ trong hộp thoại.
- **Cập nhật thông tin bản quyền VuaOffice:** Đồng bộ tên MacVietKey, liên kết GitHub 360org, website vuaoffice.com và bản quyền 360 CORP © 2026 trong hộp thoại Giới thiệu.
- **Hợp nhất Simple Telex:** Chuẩn hoá thành 1 lựa chọn Simple Telex duy nhất chuẩn Unikey / EVKey (gõ `w` ra `ư`, giữ nguyên dấu ngoặc vuông).
- **Sửa lỗi mở Bảng điều khiển:** Ánh xạ lại storyboard identifier và đưa cửa sổ nổi lên lớp trên cùng khi nhấn từ menu bar.
- **Phím tắt mặc định:** Thiết lập phím tắt chuyển ngôn ngữ mặc định thành `Control + Space`.
- **Kiến trúc Universal Binary:** Tương thích bản địa (Native) cả Apple Silicon (`arm64`) và Mac Intel (`x86_64`).
- **Bộ cài đặt đĩa ảo DMG:** Phát hành tệp cài đặt `.dmg` chuẩn Apple bên cạnh bản nén `.zip`.
- **Phát hành đa nền tảng:** Xuất bản đồng thời bộ cài đặt cho macOS, Windows (x64/x86) và Linux (Ubuntu).
- **Hỗ trợ Homebrew Cask:** Cung cấp công thức `Casks/macvietkey.rb` cho người dùng cài đặt nhanh qua dòng lệnh.

