{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libldac-dec";
  version = "2.0.72";

  src = fetchFromGitHub {
    owner = "open-vela";
    repo = "external_libldac";
    rev = "5b4bf66096ba0d69615efb2422ba3d023c34c2fd";
    hash = "sha256-5jeqTyhSBtYky15Xw1lIbUxeGZMQQQdM/EQUFicyi3Y=";
  };

  outputs = [
    "out"
    "dev"
  ];

  # Upstream ships AOSP build files and a gcc/ makefile that only knows
  # about the in-tree layout. Compile and link directly; the entire
  # library is two umbrella translation units.
  buildPhase = ''
    runHook preBuild

    $CC $NIX_CFLAGS_COMPILE -O2 -fPIC -Wall -D_DECODE_ONLY \
      -Iinc -Isrc -c src/ldaclib.c -o ldaclib.o
    $CC $NIX_CFLAGS_COMPILE -O2 -fPIC -Wall -D_DECODE_ONLY \
      -Iinc -Isrc -c src/ldacBT.c -o ldacBT.o
    $CC -shared -Wl,-soname,libldacBT_dec.so.2 \
      ldaclib.o ldacBT.o -lm -o libldacBT_dec.so.${finalAttrs.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 libldacBT_dec.so.${finalAttrs.version} \
      $out/lib/libldacBT_dec.so.${finalAttrs.version}
    ln -s libldacBT_dec.so.${finalAttrs.version} $out/lib/libldacBT_dec.so.2
    ln -s libldacBT_dec.so.${finalAttrs.version} $out/lib/libldacBT_dec.so

    install -Dm644 inc/ldacBT.h $dev/include/ldac/ldacBT.h

    mkdir -p $dev/lib/pkgconfig
    cat > $dev/lib/pkgconfig/ldacBT-dec.pc <<EOF
    prefix=$out
    exec_prefix=\''${prefix}
    libdir=$out/lib
    includedir=$dev/include/ldac

    Name: ldacBT-dec
    Description: LDAC Bluetooth decoder
    Version: ${finalAttrs.version}
    Libs: -L\''${libdir} -lldacBT_dec
    Libs.private: -lm
    Cflags: -I\''${includedir}
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Sony LDAC Bluetooth decoder library (from AOSP via open-vela)";
    homepage = "https://github.com/open-vela/external_libldac";
    license = lib.licenses.asl20;
    # LDAC bitstream format assumes LE; source has endian checks
    platforms = lib.platforms.littleEndian;
    maintainers = with lib.maintainers; [ mic92 ];
  };
})
