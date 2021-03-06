{ stdenv
, rustPlatform
, lib
, fetchFromGitHub
, ncurses
, pkg-config
, fontconfig
, python3
, openssl
, perl
, dbus
, libX11
, xcbutil
, libxcb
, xcbutilimage
, xcbutilkeysyms
, xcbutilwm # contains xcb-ewmh among others
, libxkbcommon
, libglvnd # libEGL.so.1
, egl-wayland
, wayland
, libGLU
, libGL
, freetype
, zlib
  # Apple frameworks
, CoreGraphics
, Cocoa
, Foundation
, libiconv
}:
let
  runtimeDeps = [
    zlib
    fontconfig
    freetype
  ] ++ lib.optionals (stdenv.isLinux) [
    libX11
    xcbutil
    libxcb
    xcbutilimage
    xcbutilkeysyms
    xcbutilwm
    libxkbcommon
    dbus
    libglvnd
    egl-wayland
    wayland
    libGLU
    libGL
    openssl
  ] ++ lib.optionals (stdenv.isDarwin) [
    Foundation
    CoreGraphics
    Cocoa
    libiconv
  ];
in

rustPlatform.buildRustPackage rec {
  pname = "wezterm";
  version = "20210502-154244-3f7122cb";

  src = fetchFromGitHub {
    owner = "wez";
    repo = pname;
    rev = "ac5199c21663e39dcce887308a92b5e36b338866";
    sha256 = "sha256-IK9xlmnWuK2vCdreSdJy0oANdnwvhJCug2u+pYqL9Os=";
    fetchSubmodules = true;
  };

  outputs = [ "out" "terminfo" ];

  postPatch = ''
    echo ${version} > .tag
  '';

  cargoSha256 = "sha256-9gq3Ezd/8X1bKJpea3fxDUshg/0ucy5vnCfL8zDfkOQ=";

  nativeBuildInputs = [
    pkg-config
    python3
    perl
    ncurses
  ];

  buildInputs = runtimeDeps;

  postInstall = ''
    mkdir -p $terminfo/share/terminfo/w $out/nix-support
    tic -x -o $terminfo/share/terminfo termwiz/data/wezterm.terminfo
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
  '';

  preFixup = lib.optionalString stdenv.isLinux ''
    for artifact in wezterm wezterm-gui wezterm-mux-server strip-ansi-escapes; do
      patchelf --set-rpath "${lib.makeLibraryPath runtimeDeps}" $out/bin/$artifact
    done
  '' + lib.optionalString stdenv.isDarwin ''
    mkdir -p "$out/Applications"
    OUT_APP="$out/Applications/WezTerm.app"
    cp -r assets/macos/WezTerm.app "$OUT_APP"
    rm $OUT_APP/*.dylib
    cp -r assets/shell-integration/* "$OUT_APP"
    ln -s $out/bin/{wezterm,wezterm-mux-server,wezterm-gui,strip-ansi-escapes} "$OUT_APP"
  '';

  shellHook = ''
    export LD_LIBRARY_PATH=${lib.makeLibraryPath runtimeDeps}
  '';

  # prevent further changes to the RPATH
  dontPatchELF = true;

  meta = with lib; {
    description = "A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    maintainers = with maintainers; [ steveej SuperSandro2000 ];
    platforms = platforms.unix;
  };
}
