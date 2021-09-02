{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tt-rss";
  year = "21";
  month = "09";
  day = "02";
  version = "20${year}-${month}-${day}";
  rev = "b8f82ca12f2b445c2eb74f1f3d0c12cb33b8e87f";

  src = fetchurl {
    url = "https://git.tt-rss.org/fox/tt-rss/archive/${rev}.tar.gz";
    sha256 = "sha256-E5wNEryW+P/O3qMj4uj3Lbh7UqPi4R97sJCG1lqrrtw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -ra * $out/

    # see the code of Config::get_version(). you can check that the version in
    # the footer of the preferences pages is not UNKNOWN
    echo "${year}.${month}" > $out/version_static.txt

    runHook postInstall
  '';

  meta = with lib; {
    description = "Web-based news feed (RSS/Atom) aggregator";
    license = licenses.gpl2Plus;
    homepage = "https://tt-rss.org";
    maintainers = with maintainers; [ globin zohl ];
    platforms = platforms.all;
  };
}
