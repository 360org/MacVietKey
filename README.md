# [MacVietKey](https://360org.github.io/MacVietKey/)
### [Download bản mới nhất](https://github.com/360org/MacVietKey/releases)
[![GitHub release](https://img.shields.io/github/v/release/360org/MacVietKey.svg)](https://github.com/360org/MacVietKey/releases/latest)
[![macOS Build & Release](https://github.com/360org/MacVietKey/actions/workflows/macos-build.yml/badge.svg)](https://github.com/360org/MacVietKey/actions/workflows/macos-build.yml)
[![Linux (Ubuntu) Build & Test](https://github.com/360org/MacVietKey/actions/workflows/linux-build.yml/badge.svg)](https://github.com/360org/MacVietKey/actions/workflows/linux-build.yml)

### Bộ gõ tiếng Việt chuẩn mực cho macOS — Hệ sinh thái VuaOffice (360 CORP)
MacVietKey là bộ gõ tiếng Việt mã nguồn mở tối ưu cho macOS, kế thừa nền tảng xử lý phím tốc độ cao, tích hợp cơ chế **Watchdog đa tầng** tự động phục hồi hook khi bị macOS ngắt, và tối ưu **Zero-IPC Fast-Path** triệt tiêu độ trễ phím gõ trên Spotlight, Chrome và Safari.

**Hỗ trợ kiến trúc Universal Binary:** Tương thích bản địa (Native) 100% trên cả **Apple Silicon (M1/M2/M3/M4, arm64)** và **Mac Intel (x86_64)** từ macOS 11 Big Sur đến macOS 14 Sonoma và macOS 15+ Sequoia. Đồng thời hỗ trợ đa nền tảng **Windows** và **Linux (Ubuntu)**.

---

## ⚡ Cài đặt nhanh qua Homebrew

Cài đặt trực tiếp qua lệnh Homebrew Cask:

```bash
brew install --cask https://raw.githubusercontent.com/360org/MacVietKey/master/Casks/macvietkey.rb
```

Hoặc tải file cài đặt trực tiếp:
- **macOS Universal (.zip):** **[MacVietKey-v2.2.4-macOS.dmg](https://github.com/360org/MacVietKey/releases/latest)** (Khuyên dùng) hoặc [Bản nén ZIP](https://github.com/360org/MacVietKey/releases/latest)

---

## 🌟 Điểm nổi bật kỹ thuật

- **Watchdog tự phục hồi EventTap:** Giám sát liên tục trạng thái `CGEventTapIsEnabled` mỗi giây. Khi macOS vô hiệu hoá hook do timeout, MacVietKey lập tức kích hoạt lại ngay lập tức mà không cần khởi động lại ứng dụng.
- **Tối ưu Zero-IPC:** Loại bỏ lệnh gọi quét cửa sổ `CGWindowListCopyWindowInfo` trên từng phím bấm. Xoá bỏ hoàn toàn hiện tượng lag/đơ bàn phím.
- **Phím tắt nhạy & tức thời:** Khớp chính xác cờ phím hệ thống (`_flag`) giúp các tổ hợp phím như `Control + Space` (chuyển Anh/Việt) hay `Option + Z` (mở bảng điều khiển) hoạt động 100% không trượt.
- **Bộ Identifier chuẩn VuaOffice:** `com.vuahethong.macvietkey`.
- **Hỗ trợ đầy đủ kiểu gõ:** Telex, VNI, Simple Telex.
- **Hỗ trợ trọn bộ bảng mã:** Unicode dựng sẵn, TCVN3 (ABC), VNI Windows, Unicode tổ hợp, Vietnamese Locale CP 1258.

---

## 📖 Hướng dẫn cấp quyền trên macOS

1. Tải về và kéo `MacVietKey.app` vào thư mục `/Applications`.
2. Mở **Cài đặt hệ thống (System Settings)** &rarr; **Quyền riêng tư & Bảo mật (Privacy & Security)** &rarr; **Trợ năng (Accessibility)**.
3. Gạt bật quyền cho **MacVietKey**.
4. Tắt các bộ gõ tiếng Việt cũ của Apple trong mục **Bàn phím &rarr; Nguồn nhập** để tránh xung đột.

---

## 📄 Bản quyền & Bảo trợ

Phát triển và bảo trợ bởi **360 CORP** & **VUA HỆ THỐNG** ([vuaoffice.com](https://vuaoffice.com)).  
Phát hành theo giấy phép mã nguồn mở **GNU General Public License (GPL)**.
