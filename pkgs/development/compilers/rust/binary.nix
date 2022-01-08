{ lib, stdenv, makeWrapper, bash, curl, darwin, zlib
, autoPatchelfHook
, version
, src
, platform
, versionType
}:

let
  inherit (lib) optionalString;
  inherit (darwin.apple_sdk.frameworks) Security;

  bootstrapping = versionType == "bootstrap";

  installComponents
    = "rustc,rust-std-${platform}"
    + (optionalString bootstrapping ",cargo")
    ;
in

rec {
  rustc = stdenv.mkDerivation {
    name = "rustc-${versionType}-${version}";

    inherit version;
    inherit src;

    meta = with lib; {
      homepage = "http://www.rust-lang.org/";
      description = "A safe, concurrent, practical language";
      maintainers = with maintainers; [ qknight ];
      license = [ licenses.mit licenses.asl20 ];
    };

    buildInputs = [ bash ]
      ++ lib.optional stdenv.isDarwin Security
      ++ lib.optional stdenv.hostPlatform.isMusl stdenv.cc.cc
      ++ lib.optional stdenv.isLinux zlib;

    nativeBuildInputs = lib.optional (stdenv.isLinux && bootstrapping) autoPatchelfHook;

    postPatch = ''
      patchShebangs .
    '';

    installPhase = ''
      ./install.sh --prefix=$out \
        --components=${installComponents}

      # Do NOT, I repeat, DO NOT use `wrapProgram` on $out/bin/rustc
      # (or similar) here. It causes strange effects where rustc loads
      # the wrong libraries in a bootstrap-build causing failures that
      # are very hard to track down. For details, see
      # https://github.com/rust-lang/rust/issues/34722#issuecomment-232164943
    '';

    setupHooks = ./setup-hook.sh;
  };

  cargo = stdenv.mkDerivation {
    name = "cargo-${versionType}-${version}";

    inherit version;
    inherit src;

    meta = with lib; {
      homepage = "http://www.rust-lang.org/";
      description = "A safe, concurrent, practical language";
      maintainers = with maintainers; [ qknight ];
      license = [ licenses.mit licenses.asl20 ];
    };

    nativeBuildInputs = [ makeWrapper ] ++ lib.optional (stdenv.isLinux && bootstrapping) autoPatchelfHook;
    buildInputs = [ bash ]
                  ++ lib.optional stdenv.isDarwin Security
                  ++ lib.optional stdenv.hostPlatform.isMusl stdenv.cc.cc;

    postPatch = ''
      patchShebangs .
    '';

    installPhase = ''
      patchShebangs ./install.sh
      ./install.sh --prefix=$out \
        --components=cargo

      wrapProgram "$out/bin/cargo" \
        --suffix PATH : "${rustc}/bin"
    '';
  };
}
