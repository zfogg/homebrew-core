class AsciiChat < Formula
  desc "Terminal video chat with ASCII art rendering"
  homepage "https://github.com/zfogg/ascii-chat"
  url "https://github.com/zfogg/ascii-chat/releases/download/v0.11.25/ascii-chat-0.11.25-full.tar.gz"
  sha256 "edaa79206f2cb51a66dd28da8c578d32748d05c88a12eabbc38f9d48489381bc"
  license "MIT"
  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "lld" => :build
  depends_on "llvm" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "abseil"
  depends_on "ffmpeg"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gnupg"
  depends_on "libsodium"
  depends_on "libvterm"
  depends_on "libwebsockets"
  depends_on "mimalloc"
  depends_on "miniupnpc"
  depends_on "openssl@3"
  depends_on "opus"
  depends_on "pcre2"
  depends_on "portaudio"
  depends_on "sqlite"
  depends_on "yt-dlp"
  depends_on "yyjson"
  depends_on "zstd"

  uses_from_macos "bzip2"
  uses_from_macos "curl"
  uses_from_macos "zlib"

  on_macos do
    depends_on "libnatpmp"
  end

  on_linux do
    depends_on "alsa-lib"
    depends_on "jack"
    depends_on "openssh"
    depends_on "systemd"
  end

  resource "libdatachannel" do
    url "https://github.com/paullouisageneau/libdatachannel/archive/refs/tags/v0.22.5.tar.gz"
    sha256 "bdb6aa8a79b981799282c4e71d5f9e6134b40fde2bf33f6119fd03223428d149"
  end

  resource "webrtc-aec3" do
    url "https://github.com/zhixingheyixsh/webrtc_AEC3/archive/c1dbdb9924f59d9b3c09189673286665d55f6a5e.tar.gz"
    sha256 "7a772936d667242c24e7fab07ae86c459dabe34d5465ea9e68fdda163c5305f1"
  end

  resource "nlohmann-json" do
    url "https://github.com/nlohmann/json/archive/9cca280a4d0ccf0c08f47a99aa71d1b0e52f8d03.tar.gz"
    sha256 "0dbc5e40a01ff142e7e68c03e85247a4dcede2f592d12d3677dee3664d17975a"
  end

  resource "libjuice" do
    url "https://github.com/paullouisageneau/libjuice/archive/8d1a99a0683a811876c03a73ff764a92774027ad.tar.gz"
    sha256 "edbbc2508c749b28a72039f4ba887076a2e6a064ded437f59a8ab9c53f7c278d"
  end

  resource "libsrtp" do
    url "https://github.com/cisco/libsrtp/archive/a566a9cfcd619e8327784aa7cff4a1276dc1e895.tar.gz"
    sha256 "e9ea6288246f3cb21954393a19fda09f4dd252147967a30bb8824c2168620c61"
  end

  resource "plog" do
    url "https://github.com/SergiusTheBest/plog/archive/e21baecd4753f14da64ede979c5a19302618b752.tar.gz"
    sha256 "658e037fe999036cca8b91a61ac07171980aeeaf2e3421b87c71454fdff07ce2"
  end

  resource "usrsctp" do
    url "https://github.com/sctplab/usrsctp/archive/ebb18adac6501bad4501b1f6dccb67a1c85cc299.tar.gz"
    sha256 "1281cb1acd159e359aa52285de83fa00e5c1fdf4d2edcb02f7535b9550885f1c"
  end

  def install
    resource("libdatachannel").stage buildpath/"libdatachannel"
    resource("webrtc-aec3").stage buildpath/"webrtc-aec3"
    resource("nlohmann-json").stage buildpath/"libdatachannel/deps/json"
    resource("libjuice").stage buildpath/"libdatachannel/deps/libjuice"
    resource("libsrtp").stage buildpath/"libdatachannel/deps/libsrtp"
    resource("plog").stage buildpath/"libdatachannel/deps/plog"
    resource("usrsctp").stage buildpath/"libdatachannel/deps/usrsctp"

    ENV.llvm_clang
    rpath_dependencies = %w[
      abseil ffmpeg fontconfig freetype libsodium libvterm libwebsockets mimalloc
      miniupnpc openssl@3 opus pcre2 portaudio sqlite yyjson zstd
    ]
    rpath_dependencies += %w[alsa-lib jack systemd] if OS.linux?
    rpaths = ["$ORIGIN/../lib", *rpath_dependencies.map { |dependency| formula_opt_lib(dependency) }]
    ENV.append "LDFLAGS", "-L#{formula_opt_lib("openssl@3")}"
    ENV.append "LDFLAGS", "-L#{formula_opt_lib("sqlite")}"
    if OS.linux?
      ENV.append "LDFLAGS", "-L#{formula_opt_lib("jack")}"
      ENV.append "LDFLAGS", "-L#{formula_opt_lib("systemd")}"
    end
    args = %W[
      -DASCIICHAT_ENABLE_ANALYZERS=OFF
      -DASCIICHAT_RELEASE_CPU_CUSTOM_FLAGS=#{Hardware::CPU.arm? ? "-march=armv8-a" : "-march=x86-64"}
      -DASCIICHAT_RELEASE_CPU_TUNE=custom
      -DASCIICHAT_SIMD_MODE=#{Hardware::CPU.arm? ? "neon" : "sse2"}
      -DASCIICHAT_SHARED_DEPS=ON
      -DBUILD_TESTS=OFF
      -DCMAKE_BUILD_RPATH=#{rpaths.join(";")}
      -DCMAKE_C_COMPILER=#{ENV["CC"]}
      -DCMAKE_CXX_COMPILER=#{ENV["CXX"]}
      -DCMAKE_PREFIX_PATH=#{HOMEBREW_PREFIX}
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON
      -DFETCHCONTENT_SOURCE_DIR_LIBDATACHANNEL=#{buildpath}/libdatachannel
      -DFETCHCONTENT_SOURCE_DIR_WEBRTC_AEC3=#{buildpath}/webrtc-aec3
      -DUSE_CPACK=OFF
      -DUSE_MUSL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  service do
    run [opt_bin/"ascii-chat", "server"]
    keep_alive crashed: true
    working_dir var
    log_path var/"log/ascii-chat.log"
    error_log_path var/"log/ascii-chat.log"
  end

  test do
    output = shell_output("#{bin}/ascii-chat --show-capabilities")
    assert_match "Terminal Capabilities", output
    assert_match "UTF-8 Support", output
  end
end
