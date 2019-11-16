{ stdenv, fetchurl, lib }:

stdenv.mkDerivation rec {
  name = "kmod-debian-aliases-${version}.conf";
  version = "26-3";

  src = fetchurl {
    url = "https://snapshot.debian.org/archive/debian/20190918T030259Z/pool/main/k/kmod/kmod_${version}.debian.tar.xz";
    sha256 = "0gfdbn6qv03s9pp8wp4rgikqrlz6dry36h39cx95clpvplxjsrnc";
  };

  installPhase = ''
    patch -i patches/aliases_conf
    cp aliases.conf $out
  '';

  meta = {
    homepage = https://packages.debian.org/source/sid/kmod;
    description = "Linux configuration file for modprobe";
    maintainers = with lib.maintainers; [ mathnerd314 ];
    platforms = with lib.platforms; linux;
  };
}
