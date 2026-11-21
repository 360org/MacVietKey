# MacVietKey — Changelog

## v2.2.1 (2026-11-21) — Phát Hành Bản Nâng Cấp Hoàn Thiện & Audit Toàn Diện
-------------------------------------------------------------------------
- [BRANDING] Rà soát và chuyển đổi 100% thông tin trong tab Thông tin của Bảng điều khiển sang 360 CORP & VUA HỆ THỐNG:
  * Trang chủ chính thức: https://360org.github.io/MacVietKey/
  * Website hệ sinh thái: https://vuaoffice.com
  * Hòm thư hỗ trợ kỹ thuật: support@360.org.vn
  * Bản quyền pháp lý: 360 CORP & VUA HỆ THỐNG © 2026
  * Sửa sạch triệt để toàn bộ chuỗi cũ trong tệp giao diện nhị phân NIB và mã nguồn ViewController.m.
- [UI] Bổ sung hàm đệ quy updateInfoLabelsInView: tự động chuẩn hóa nhãn khi bảng điều khiển mở lên.
- [SHORTCUT] Khóa cứng phím tắt chuyển ngôn ngữ mặc định thành Control + Space (0x31000131).
- [RELEASE] Đóng gói bộ cài đặt đĩa ảo MacVietKey-v2.2.1-macOS.dmg và bản nén ZIP Universal Binary.

## v2.2.0 (2026-11-20) — Bản Phát Hành Chính Thức Toàn Diện (Hệ Sinh Thái VuaOffice)
----------------------------------------------------------------------------------

### 1. Khắc phục triệt để lỗi gõ phím & Tích hợp Watchdog từ EVKey
- **[WATCHDOG] Tự động phục hồi EventTap:** Tích hợp bộ giám sát ngầm chạy chu kỳ 1.0 giây bằng GCD Dispatch Timer. Khi macOS tự động vô hiệu hoá hook bàn phím do timeout (`kCGEventTapDisabledByTimeout` hoặc `kCGEventTapDisabledByUserInput`), MacVietKey lập tức kích hoạt lại ngay tức thì mà không cần khởi động lại ứng dụng.
- **[PERF] Tối ưu hóa Zero-IPC Fast-Path:** Loại bỏ hoàn toàn lệnh gọi `CGWindowListCopyWindowInfo` trên mỗi phím bấm trong hàm kiểm tra Spotlight. Triệt tiêu 100% hiện tượng lag/đơ bàn phím khi soạn thảo trên Spotlight, Google Chrome và Safari.
- **[ENGINE] Vá lỗi rò rỉ bộ nhớ CoreFoundation:** Loại bỏ lệnh gọi `CFRelease(langRef)` dư thừa trên đối tượng lấy từ mảng trong hàm kiểm tra ngôn ngữ bàn phím, ngăn ngừa lỗi crash ngầm.

### 2. Sửa lỗi mất quyền Trợ năng (Accessibility) khi tắt máy mở lại
- **[TCC] Nhúng Designated Requirement cố định:** Ký chữ ký số ứng dụng với tham số `designated => identifier "com.vuahethong.vuaoffice.macvietkey"`. Cơ sở dữ liệu bảo mật TCC của macOS ghi nhận quyền vĩnh viễn theo Bundle ID thay vì mã băm nhị phân tạm thời, không bao giờ bị hỏi lại quyền sau khi khởi động lại máy.
- **[BOOT] Bổ sung vòng lặp chờ khởi động an toàn:** Thêm cơ chế kiểm tra 10 lần với độ trễ 500ms khi máy vừa bật lên để chờ dịch vụ bảo mật TCC nạp xong dữ liệu, xoá bỏ hoàn toàn các cảnh báo cấp quyền giả mạo lúc khởi động.
- **[UX] Tự động kích hoạt khi bật quyền:** Bổ sung luồng tự động nhận diện khi người dùng vừa gạt bật quyền trong Cài đặt hệ thống để tiếp tục chạy bàn phím ngay lập tức mà không bắt buộc tắt đi bật lại phần mềm.

### 3. Nhận diện thương hiệu chuẩn 360 CORP & VuaOffice
- **[ICON] Bộ biểu tượng Apple ICNS chính thức:** Trích xuất và tạo bộ `Icon.icns` đầy đủ 10 tầng chuẩn Retina từ bản thiết kế chính thức (nền vuông bo góc xanh công nghệ, chữ V và phím Command ⌘).
- **[ALERT] Gán biểu tượng trực tiếp cho hộp thoại:** Bổ sung lệnh nạp và gán `[alert setIcon:appIcon]` và `[NSApp setApplicationIconImage:appIcon]` trực tiếp trong mã nguồn, loại bỏ hoàn toàn biểu tượng chữ V màu đỏ cũ của OpenKey.
- **[BRANDING] Cập nhật toàn diện hộp thoại Giới thiệu (About):** Chuyển đổi tên ứng dụng thành `MacVietKey`, cập nhật liên kết trang chủ GitHub `https://github.com/360org/MacVietKey`, website `https://vuaoffice.com` và bản quyền `360 CORP & VUA HỆ THỐNG © 2026`.
- **[IDENTIFIER] Chuẩn hoá hệ thống phân cấp Bundle ID:**
  * Application Bundle ID: `com.vuahethong.vuaoffice.macvietkey`
  * Helper Bundle ID: `com.vuahethong.vuaoffice.macvietkey.helper`
  * Category: `public.app-category.productivity`

### 4. Tinh chỉnh giao diện & Phím tắt tiện dụng
- **[UI] Hợp nhất kiểu gõ Simple Telex:** Loại bỏ phân nhánh gây khó hiểu (Simple Telex 1 và 2), gộp thành một lựa chọn duy nhất **Simple Telex** chuẩn theo Unikey và EVKey (gõ `w` ra `ư`, giữ nguyên phím ngoặc vuông `[` `]` cho người dùng văn phòng và lập trình).
- **[FIX] Sửa lỗi mở Bảng điều khiển (Control Panel):** Bổ sung ánh xạ định danh storyboard trong `Main.storyboardc/Info.plist`, thêm cơ chế fallback và lệnh `[NSApp activateIgnoringOtherApps:YES]` giúp cửa sổ bảng điều khiển luôn nổi lên lớp trên cùng khi bấm từ thanh menu.
- **[SHORTCUT] Thiết lập phím tắt mặc định:** Cập nhật phím tắt chuyển ngôn ngữ mặc định thành **`Control + Space`** trong cả mã nguồn cốt lõi và cấu hình người dùng.

### 5. Đa nền tảng, Đóng gói DMG & Tự động hoá CI/CD
- **[ARCH] macOS Universal Binary:** Tệp thực thi nhị phân hợp nhất hỗ trợ bản địa (Native) 100% trên cả **Apple Silicon (M1/M2/M3/M4, arm64)** và **Mac Intel (x86_64)**.
- **[DMG] Bộ cài đặt đĩa ảo macOS (.dmg):** Đóng gói bộ cài đặt chuẩn Apple với đường dẫn tắt kéo thả vào thư mục `/Applications`.
- **[MULTI-PLATFORM] Hỗ trợ song song Windows và Linux:**
  * Windows 64-bit và 32-bit đóng gói tự động qua MSBuild.
  * Linux Ubuntu 22.04 / 24.04 biên dịch Engine xử lý tiếng Việt CLI và bộ thư viện C++ tương thích.
- **[HOMEBREW] Công thức Homebrew Cask:** Cung cấp tệp `Casks/macvietkey.rb` hỗ trợ cài đặt nhanh qua lệnh `brew install --cask`.
- **[DOCS] Trang tài liệu trực tuyến GitHub Pages:** Xây dựng website tài liệu chuyên nghiệp chuẩn phong cách VuaOffice tại `https://360org.github.io/MacVietKey/`.
