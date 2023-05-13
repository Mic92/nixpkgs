{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, libuuid
, libsodium
, keyutils
, liburcu
, zlib
, libaio
, zstd
, lz4
, attr
, udev
, valgrind
, nixosTests
, fuse3
, cargo
, rustc
, coreutils
, rustPlatform
, makeWrapper
, fuseSupport ? false
}:
let
  rev = "5ef62f56ab50c5799f713e3a42f5c7ad7e8283d3";
in stdenv.mkDerivation {
  pname = "bcachefs-tools";
  version = "unstable-2023-05-13";

  src = fetchFromGitHub {
    owner = "koverstreet";
    repo = "bcachefs-tools";
    inherit rev;
    hash = "sha256-w8ez7+E4suPN0W5OzbzFLysDXlmZrjFk20f8VZlIfuE=";
  };

  nativeBuildInputs = [
    pkg-config
    cargo
    rustc
    rustPlatform.cargoSetupHook
    rustPlatform.bindgenHook
    makeWrapper
  ];

  cargoRoot = "rust-src";
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "bindgen-0.64.0" = "sha256-GNG8as33HLRYJGYe0nw6qBzq86aHiGonyynEM7gaEE4=";
    };
  };

  buildInputs = [
    libaio
    keyutils
    lz4

    libsodium
    liburcu
    libuuid
    zstd
    zlib
    attr
    udev
  ] ++ lib.optional fuseSupport fuse3;

  doCheck = false; # needs bcachefs module loaded on builder
  checkFlags = [ "BCACHEFS_TEST_USE_VALGRIND=no" ];
  nativeCheckInputs = [ valgrind ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "VERSION=${lib.strings.substring 0 7 rev}"
    "INITRAMFS_DIR=${placeholder "out"}/etc/initramfs-tools"
  ];

  preCheck = lib.optionalString fuseSupport ''
    rm tests/test_fuse.py
  '';

  passthru.tests = {
    smoke-test = nixosTests.bcachefs;
    inherit (nixosTests.installer) bcachefsSimple bcachefsEncrypted bcachefsMulti;
  };

  postFixup = ''
    wrapProgram $out/bin/mount.bcachefs \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Tool for managing bcachefs filesystems";
    homepage = "https://bcachefs.org/";
    license = licenses.gpl2;
    maintainers = with maintainers; [ davidak Madouura ];
    platforms = platforms.linux;
  };
}
