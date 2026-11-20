# MacVietKey — Changelog

## v2.1.1 (2026-11-20)
-----------------------
- [REFACTOR] Đổi tên toàn diện thương hiệu và định danh từ OpenKey sang MacVietKey.
- [REFACTOR] Cập nhật Bundle Identifier thành com.360org.macvietkey và com.360org.macvietkey.helper.
- [REFACTOR] Đồng bộ thư mục lưu trữ Application Support sang ~/Library/Application Support/MacVietKey.
- [REFACTOR] Cập nhật toàn bộ liên kết dự án, repository và releases sang 360org/MacVietKey trên GitHub.
- [CI] Cập nhật workflow msbuild và macos-build xuất artifact với tên MacVietKey.

## v2.1.0 (2026-11-20)
-----------------------
- [FIX] Sửa triệt để lỗi liệt EventTap và ngắt phím gõ tiếng Việt trên macOS Sequoia/Sonoma do `kCGEventTapDisabledByTimeout` không được phục hồi.
- [NEW] Tích hợp cơ chế Watchdog đa tầng (tương tự EVKey) tự động kiểm tra `CGEventTapIsEnabled` mỗi giây và kích hoạt lại ngay khi hệ thống ngắt hook.
- [FIX] Loại bỏ lệnh gọi IPC nặng `CGWindowListCopyWindowInfo` trên mỗi keystroke trong hàm kiểm tra Spotlight, triệt tiêu hoàn toàn hiện tượng lag/đơ bàn phím.
- [FIX] Khắc phục lỗi phím tắt chuyển ngôn ngữ và mở bảng điều khiển: kiểm tra trực tiếp bitmask cờ phím (`_flag`) thay vì dựa vào biến trung gian `_lastFlag` dễ bị trôi.
- [FIX] Vá lỗi rò rỉ bộ nhớ và crash tiềm ẩn do gọi `CFRelease` sai trên biến `langRef` trong `OpenKeyCallback`.
- [IMPROVE] Cập nhật nhận diện bundle name hiển thị chuẩn `MacVietKey`.
- [TEST] Bổ sung bộ kiểm thử 10 test cases độc lập bao phủ Telex, Unicode dựng sẵn, tổ hợp phụ âm, bỏ dấu, phím tắt và Watchdog recovery.
- [CI] Thêm GitHub Actions workflow `macos-build.yml` tự động build và đóng gói artifact trên macOS.
