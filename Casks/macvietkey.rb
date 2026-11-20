cask "macvietkey" do
  version "2.2.0"
  sha256 "69c9add3a5f49b214389fdbce478792a8ec702dd05289383b2f0ef1d2360c2a3"

  url "https://github.com/360org/MacVietKey/releases/download/v#{version}/MacVietKey-v#{version}-macOS.dmg"
  name "MacVietKey"
  desc "Bộ gõ tiếng Việt chuẩn mực cho macOS (Hệ sinh thái VuaOffice)"
  homepage "https://360org.github.io/MacVietKey/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "MacVietKey.app"

  zap trash: [
    "~/Library/Application Support/MacVietKey",
    "~/Library/Caches/com.vuahethong.vuaoffice.macvietkey",
    "~/Library/HTTPStorages/com.vuahethong.vuaoffice.macvietkey",
    "~/Library/Preferences/com.vuahethong.vuaoffice.macvietkey.plist",
    "~/Library/Saved Application State/com.vuahethong.vuaoffice.macvietkey.savedState",
  ]
end
