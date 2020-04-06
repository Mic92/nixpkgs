{ stdenv
, fetch
, cmake
, libxml2
, llvm
, version
, buildPackages
}:

stdenv.mkDerivation {
  pname = "lld";
  inherit version;

  src = fetch "lld" "0rsqb7zcnij5r5ipfhr129j7skr5n9pyr388kjpqwh091952f3x1";

  nativeBuildInputs = [ cmake ];
  buildInputs = [ libxml2 llvm ];

  cmakeFlags = [
    "-DLLVM_CONFIG_PATH=${buildPackages.llvm}/bin/llvm-config"
  ];

  outputs = [ "out" "dev" ];

  enableParallelBuilding = true;

  postInstall = ''
    moveToOutput include "$dev"
    moveToOutput lib "$dev"
  '';

  meta = {
    description = "The LLVM Linker";
    homepage    = http://lld.llvm.org/;
    license     = stdenv.lib.licenses.ncsa;
    platforms   = stdenv.lib.platforms.all;
  };
}
