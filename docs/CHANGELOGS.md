# MacVietKey — Changelog

## v2.2.0 (2026-11-20)
-----------------------
- [RELEASE] Phát hành chính thức phiên bản **MacVietKey v2.2.0** kế thừa và nâng cấp toàn diện từ OpenKey và EVKey.
- [IDENTIFIER] Chuẩn hoá toàn bộ bộ Identifier theo hệ sinh thái VuaOffice:
  * Application Bundle ID: `com.vuahethong.macvietkey`
  * Helper Bundle ID: `com.vuahethong.macvietkey.helper`
  * Thư mục cấu hình: `~/Library/Application Support/MacVietKey`.
- [WATCHDOG] Tích hợp cơ chế Watchdog đa tầng (từ EVKey) tự động kiểm tra `CGEventTapIsEnabled` mỗi giây và kích hoạt lại ngay khi hệ thống ngắt hook.
- [ENGINE] Sửa triệt để lỗi liệt EventTap và ngắt phím gõ tiếng Việt trên macOS Sequoia & Sonoma do `kCGEventTapDisabledByTimeout`.
- [PERF] Tối ưu hóa Zero-IPC: Loại bỏ lệnh gọi nặng `CGWindowListCopyWindowInfo` trên mỗi phím bấm, triệt tiêu 100% hiện tượng lag/đơ bàn phím.
- [SHORTCUT] Khắc phục lỗi phím tắt chuyển ngôn ngữ (Control+Space / Option+Z): kiểm tra trực tiếp cờ phím hệ thống `_flag`.
- [DOCS] Xuất bản trang tài liệu trực tuyến chuyên nghiệp chuẩn phong cách VuaOffice tại `docs/index.html` và `docs/changelog.html`.
- [CI/CD] Thiết lập tự động hoá biên dịch Xcode trên macOS Runner và tự động tạo GitHub Release đính kèm file cài đặt `.zip` khi gắn thẻ release.
