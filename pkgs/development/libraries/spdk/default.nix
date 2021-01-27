{ lib, stdenv
, fetchurl
, fetchFromGitHub
, fetchpatch
, ncurses
, python3
, cunit
, dpdk
, libaio
, libbsd
, libuuid
, numactl
, openssl
, yasm
, autoconf
, automake
, libtool
}:

stdenv.mkDerivation rec {
  pname = "spdk";
  version = "20.10";

  src = fetchFromGitHub {
    owner = "spdk";
    repo = "spdk";
    rev = "v${version}";
    sha256 = "sha256-TVQU1FV0BvYkqpYbxNtqkE6pfkO3vhaK5CHSfbqh99Y=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    python3
    yasm
    autoconf
    automake
    libtool
    libbsd
  ];

  buildInputs = [
    cunit dpdk libaio libbsd libuuid numactl openssl ncurses
  ];

  postPatch = ''
    patchShebangs .
  '';

  configureFlags = [ "--with-dpdk=${dpdk}" ];

  NIX_CFLAGS_COMPILE = [
    # Necessary to compile.
    "-mssse3"
    # somehow it depends on strlcpy
    "-lbsd"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Set of libraries for fast user-mode storage";
    homepage = "https://spdk.io/";
    license = licenses.bsd3;
    platforms =  [ "x86_64-linux" ];
    maintainers = with maintainers; [ orivej ];
  };
}
