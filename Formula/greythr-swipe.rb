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
  url "https://github.com/direwolfv/greythr-swipe/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "b5031c30e21ad5e223d8058563ad22e35d9191b574fb35742768653436972302"
  license "ISC"

  # build.sh compiles App.swift with swiftc. No node dependency: Homebrew's node pulls 16
  # libraries of its own, and run.sh finds the user's node at run time.
  depends_on xcode: :build
  depends_on :macos

  # The only runtime dependency, fetched straight from the registry so the build needs no npm.
  # playwright-core has no dependencies of its own. Keep in step with package-lock.json.
  resource "playwright-core" do
    url "https://registry.npmjs.org/playwright-core/-/playwright-core-1.63.0.tgz"
    sha256 "208593d4e1bcd8f8fe5f869cad1cc332dc7f1d70dc1d58c102dc3ac36e30f26c"
  end

  def install
    resource("playwright-core").stage(buildpath/"node_modules/playwright-core")
    system "./app/build.sh", "--no-migrate"
    prefix.install "app/greytHR.app"

    # Formulae have no uninstall or zap hook (cask-only), so `brew uninstall` cannot stop
    # the LaunchAgent it left behind. Ship a command that does.
    bin.install "app/uninstall.sh" => "greythr-swipe-uninstall"
  end

  # The symlink is manual because Homebrew sandboxes post-install: a formula cannot write
  # outside its own prefix (verified — File.symlink raises EPERM there). It is also required,
  # not cosmetic: SMAppService registers the timer only for an app reachable under
  # /Applications, and reports .notFound anywhere else.
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
