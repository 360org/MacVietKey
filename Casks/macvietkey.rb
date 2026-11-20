cask "macvietkey" do
  version "2.2.0"
  sha256 "eb292deade32ec145f849a7c0fb9a064dbf9a68f6daf3d4b976b3722848b90ee"

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
    "~/Library/Caches/com.vuahethong.macvietkey",
    "~/Library/HTTPStorages/com.vuahethong.macvietkey",
    "~/Library/Preferences/com.vuahethong.macvietkey.plist",
    "~/Library/Saved Application State/com.vuahethong.macvietkey.savedState",
  ]
end
