# Homebrew formula — builds from source on the user's machine, so no Developer ID is needed
# and Gatekeeper never quarantines the app.
#
#   brew tap direwolfv/tap
#   brew install direwolfv/tap/homebrew-manager
class HomebrewManager < Formula
  desc "Native macOS app to browse, upgrade and uninstall your Homebrew packages"
  homepage "https://github.com/direwolfv/homebrew-manager"
  url "https://github.com/direwolfv/homebrew-manager/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "4396a49eea07255cd55b6233fc582f48a3bc398a6e4633d7aa9311e967aa3f66"
  license "ISC"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :sonoma

  def install
    # SwiftPM's own sandbox cannot nest inside Homebrew's.
    system "./app/build.sh", "--disable-sandbox"
    prefix.install "Homebrew Manager.app"
  end

  # Post-install is sandboxed to the prefix, so the /Applications link has to be manual.
  def caveats
    <<~EOS
      Link it into /Applications and launch it:
        ln -sfn "#{opt_prefix}/Homebrew Manager.app" "/Applications/Homebrew Manager.app"
        open "/Applications/Homebrew Manager.app"
    EOS
  end

  test do
    assert_predicate prefix/"Homebrew Manager.app/Contents/MacOS/HomebrewManager", :executable?
  end
end
