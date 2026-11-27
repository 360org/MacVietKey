cask "macvietkey" do
  version "2.2.4"
  sha256 "867ce4a3cf2ac081c5f430b7f5a1ec25056fa88d0ebcfb9ce3760ec14c548b72"

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
    "~/Library/LaunchAgents/com.vuahethong.vuaoffice.macvietkey.plist",
  ]
end
