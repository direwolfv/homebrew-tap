# Homebrew formula — builds from source on the user's machine.
#
# Deliberately a formula and not a cask: a cask ships a prebuilt binary, which macOS
# quarantines unless it is signed with a paid Developer ID. Compiling locally sidesteps
# Gatekeeper entirely and costs nothing.
#
# This tap is the only home for the formula — Homebrew loads formulae from a tap, and a
# copy in the source repo would chase its own sha256 through every release.
#
#   brew tap direwolfv/tap
#   brew install direwolfv/tap/greythr-swipe   # or just: brew install greythr-swipe
class GreythrSwipe < Formula
  desc "Menu bar app that signs you in and out of greytHR on a schedule"
  homepage "https://github.com/direwolfv/greythr-swipe"
  url "https://github.com/direwolfv/greythr-swipe/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "7ed47bf63c21363ce089b079ea9ee4b11c0c1e71526c4d95e3f87ee2ee61126b"
  license "ISC"

  # build.sh compiles App.swift with swiftc; node runs the devDependency prune.
  depends_on xcode: :build
  depends_on :macos
  depends_on "node"

  def install
    # Belt and braces: the dependency is playwright-core, which has no browser-download
    # step at all, and this env var stops any transitive one too.
    ENV["PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD"] = "1"

    # Use the dependency's own npm rather than whatever PATH offers, and say so plainly if
    # it is missing — `npm ci` on its own would just exit 127. build.sh needs node too, so
    # put the dependency first on PATH for it.
    node_bin = formula_opt_bin("node")
    odie "node dependency is missing: #{node_bin}/npm not found" unless (node_bin/"npm").exist?
    ENV.prepend_path "PATH", node_bin

    system node_bin/"npm", "ci", "--omit=dev"
    system "./app/build.sh", "--no-migrate"
    prefix.install "app/greytHR.app"

    # Formulae have no uninstall or zap hook (cask-only), so `brew uninstall` cannot stop
    # the LaunchAgent it left behind. Ship a command that does.
    bin.install "app/uninstall.sh" => "greythr-swipe-uninstall"
  end

  # The symlink is manual because Homebrew sandboxes post-install: a formula cannot write
  # outside its own prefix (verified — File.symlink raises EPERM there). Only a cask can
  # place an app in /Applications, and a cask needs a paid Developer ID to clear Gatekeeper.
  def caveats
    <<~EOS
      Link it into /Applications and launch it:
        ln -sfn #{opt_prefix}/greytHR.app /Applications/greytHR.app
        open /Applications/greytHR.app

      First launch installs a LaunchAgent (a 5-minute timer). Open Settings from the menu
      bar icon to add your greytHR URL, credentials and times.

      Uninstall — run this FIRST, it stops the timer that `brew uninstall` cannot:
        greythr-swipe-uninstall --all   # omit --all to keep settings and credentials
        brew uninstall direwolfv/tap/greythr-swipe
    EOS
  end

  test do
    assert_predicate prefix/"greytHR.app/Contents/MacOS/greytHR", :executable?
    assert_path_exists prefix/"greytHR.app/Contents/Resources/index.js"
  end
end
