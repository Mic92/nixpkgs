{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "freebsd-libc";
  version = "11.2";
  src = fetchurl {
    url = "http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/${version}-RELEASE/base.txz";
    sha256 = "06gxjs27vrmki5idwjclxna6i51n91w02vfs59glzbb20ilvw0m0";
  };

  unpackPhase = ''
    tar -xf $src
  '';

  installPhase = ''
    mkdir $out
    cp -r usr/include $out/include
    cp -r usr/lib $out/lib
  '';
}
