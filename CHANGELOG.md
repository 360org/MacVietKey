# MacVietKey Change Log

##### Version 2.2.2: (23/11/2026) — Sửa dứt điểm lỗi tự bật Bảng điều khiển khi mở máy
- Sửa triệt để lỗi Bảng điều khiển tự bật lên khi khởi động macOS dù không chọn tùy chọn này.
- Khởi động hoàn toàn ẩn dưới thanh menu thông qua LaunchAgent chạy trực tiếp tệp nhị phân nền.
- Cơ chế thử lại khởi tạo hook bàn phím trong yên lặng (startEventTapQuietly).
- Phát hành bộ cài đặt đĩa ảo MacVietKey-v2.2.2-macOS.dmg và bản nén ZIP Universal Binary.

##### Version 2.2.1: (21/11/2026) — Phát hành bản nâng cấp hoàn thiện 360org & VuaOffice
- Chuẩn hóa 100% thông tin trong tab Thông tin của Bảng điều khiển sang 360 CORP & VUA HỆ THỐNG.
- Cập nhật trang chủ https://360org.github.io/MacVietKey/, website https://vuaoffice.com và email support@360.org.vn.
- Phím tắt chuyển ngôn ngữ mặc định Control + Space.
- Đóng gói đĩa ảo MacVietKey-v2.2.1-macOS.dmg và tệp nén Universal ZIP.

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

