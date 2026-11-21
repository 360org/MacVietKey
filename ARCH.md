# Kiến trúc Kỹ thuật MacVietKey (macOS Input Engine)

## 1. Tổng quan
MacVietKey là bộ gõ tiếng Việt hiệu năng cao cho macOS kế thừa lõi xử lý ký tự của OpenKey và cơ chế an toàn, độ bền hook từ EVKey.

## 2. Các thành phần chính
- **EventTap Hook (`OpenKeyCallback`)**: Đón bắt các sự kiện bàn phím mức hệ thống thông qua `CGEventTapCreate`.
- **EventTap Watchdog (`OpenKeyManager startWatchdog`)**: Sử dụng GCD Dispatch Timer chu kỳ 1.0 giây kiểm tra trạng thái `CGEventTapIsEnabled`. Nếu phát hiện EventTap bị vô hiệu hoá do timeout hệ thống, hàm `reenableEventTap` được gọi tức thì.
- **Vietnamese Engine Core (`Sources/OpenKey/engine/`)**: Máy trạng thái xử lý bảng mã Unicode, TCVN3, VNI và các kiểu gõ Telex, VNI.
- **Fast-path Optimization**: Bộ đệm tiến trình hoạt động hiện tại (`_frontMostApp`) loại bỏ hoàn toàn các lời gọi Window Server IPC tốn kém trên từng phím bấm.
