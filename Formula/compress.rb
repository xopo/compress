class Mytool < Formula
  desc "binary that watch folder for mov and convert with ffmpet go mp4"
  homepage "https://github.com/xopo/compress"
  url "https://github.com/xopo/compress/releases/download/0.1_alpha_mac_silicon/compress.tar.gz"
  sha256 "6376744e50716b704079314d95d5485f9b990c7c7b4ddda39f7dd5daed828c67" # Get this via 'shasum -a 256 filename'
  license "MIT"

  def install
    # If it's a Go/Rust/Compiled binary:
    bin.install "mytool"
    
    # If it's a script (like Python or Bash):
    # bin.install "mytool.sh" => "mytool"
  end

  test do
    system "#{bin}/mytool", "--version"
  end
end
