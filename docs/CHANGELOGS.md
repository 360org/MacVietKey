# MacVietKey — Changelog

## v2.1.1 (2026-11-20)
-----------------------
- [IDENTIFIER] Cập nhật toàn bộ hệ thống Identifier sang chuẩn VuaOffice:
  * Application Bundle ID: `com.vuahethong.macvietkey`
  * Helper Bundle ID: `com.vuahethong.macvietkey.helper`
  * Đồng bộ trong `project.pbxproj`, `AppDelegate.h`, `Info.plist`, và `OpenKey.mm`.
- [DOCS] Xây dựng trang tài liệu trực tuyến chuyên nghiệp chuẩn phong cách VuaOffice (`docs/index.html` và `docs/changelog.html`):
  * Bảng so sánh tính năng kỹ thuật với EVKey, OpenKey cũ và Bộ gõ mặc định Apple.
  * Hướng dẫn cài đặt và cấp quyền Accessibility trên macOS Sequoia & Sonoma.
  * Danh mục phím tắt tiện dụng (Control+Space, Option+Z, Control+Option+C).
- [URL] Thay thế toàn bộ địa chỉ liên kết cũ `open-key.org` sang trang tài liệu chính thức GitHub Docs.
- [CI] Thêm GitHub Actions workflow `.github/workflows/pages.yml` tự động xuất bản GitHub Pages.

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
