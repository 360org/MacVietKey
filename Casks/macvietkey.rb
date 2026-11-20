cask "macvietkey" do
  version "2.2.0"
  sha256 "2cde8a5418a8864b4f53973b871ba2664e426588dab666dde3af48910c95e84f"

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
