# MacVietKey — Changelog

## v1.0.0 (2026-11-20)
-----------------------
- [NEW] Phát hành phiên bản chính thức đầu tiên **MacVietKey v1.0.0** cho macOS.
- [IDENTIFIER] Chuẩn hoá toàn bộ bộ Identifier theo hệ sinh thái VuaOffice:
  * Application Bundle ID: `com.vuahethong.macvietkey`
  * Helper Bundle ID: `com.vuahethong.macvietkey.helper`
  * Thư mục cấu hình: `~/Library/Application Support/MacVietKey`.
- [ENGINE] Sửa triệt để lỗi liệt EventTap và ngắt phím gõ tiếng Việt trên macOS Sequoia/Sonoma do `kCGEventTapDisabledByTimeout`.
- [WATCHDOG] Tích hợp cơ chế Watchdog đa tầng (tương tự EVKey) tự động kiểm tra `CGEventTapIsEnabled` mỗi giây và kích hoạt lại ngay khi hệ thống ngắt hook.
- [PERF] Loại bỏ lệnh gọi IPC nặng `CGWindowListCopyWindowInfo` trên mỗi keystroke, triệt tiêu hoàn toàn hiện tượng lag/đơ bàn phím.
- [SHORTCUT] Khắc phục lỗi phím tắt chuyển ngôn ngữ (Control+Space / Option+Z): kiểm tra trực tiếp cờ phím hệ thống `_flag`.
- [DOCS] Xuất bản trang tài liệu trực tuyến chuyên nghiệp chuẩn phong cách VuaOffice tại `docs/index.html` và `docs/changelog.html`.
- [CI/CD] Thiết lập tự động hoá biên dịch Xcode trên macOS Runner và tự động tạo GitHub Release đính kèm file cài đặt `.zip` khi gắn thẻ release.
