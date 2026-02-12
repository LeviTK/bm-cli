class BmCli < Formula
  desc "Agent-first Mermaid CLI renderer (terminal + SVG)"
  homepage "https://github.com/<OWNER>/bm-cli"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/<OWNER>/bm-cli/releases/download/v#{version}/bm-cli-darwin-arm64.tar.gz"
      sha256 "<REPLACE_WITH_ARM64_SHA256>"
    end

    on_intel do
      url "https://github.com/<OWNER>/bm-cli/releases/download/v#{version}/bm-cli-darwin-x64.tar.gz"
      sha256 "<REPLACE_WITH_X64_SHA256>"
    end
  end

  def install
    bin.install "bm-cli"
  end

  test do
    output = shell_output("#{bin}/bm-cli agent capabilities --json")
    assert_match "\"ok\":", output
  end
end
