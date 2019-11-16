{ stdenv, fetchurl, gnugrep, findutils }:

let
  version = "26-1ubuntu1"; # Eoan

in stdenv.mkDerivation {
  pname = "kmod-blacklist";
  inherit version;

  src = fetchurl {
    url = "https://launchpad.net/ubuntu/+archive/primary/+files/kmod_${version}.debian.tar.xz";
    sha256 = "1mpkqjq42y4ydln0hlhy89jryavgyrb18yazh5nk3yqjmzzzddva";
  };

  installPhase = ''
    mkdir "$out"
    for f in modprobe.d/*.conf; do
      echo "''\n''\n## file: "`basename "$f"`"''\n''\n" >> "$out"/modprobe.conf
      cat "$f" >> "$out"/modprobe.conf
      # https://bugs.launchpad.net/ubuntu/+source/kmod/+bug/1475945
      sed -i '/^blacklist i2c_i801/d' $out/modprobe.conf
    done

    substituteInPlace "$out"/modprobe.conf \
      --replace "blacklist bochs-drm" "" \
      --replace /sbin/lsmod /run/booted-system/sw/bin/lsmod \
      --replace /sbin/rmmod /run/booted-system/sw/bin/rmmod \
      --replace /sbin/modprobe /run/booted-system/sw/bin/modprobe \
      --replace " grep " " ${gnugrep}/bin/grep " \
      --replace " xargs " " ${findutils}/bin/xargs "
  '';

  meta = with stdenv.lib; {
    homepage = https://packages.ubuntu.com/source/zesty/kmod;
    description = "Linux kernel module blacklists from Ubuntu";
    platforms = platforms.linux;
  };
}
