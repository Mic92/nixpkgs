{ lib, stdenv, fetchFromGitHub, capstone, libbfd, libelf, libiberty, readline }:

stdenv.mkDerivation {
  pname = "wcc-unstable";
  version = "2022-11-06";

  src = fetchFromGitHub {
    owner = "endrazine";
    repo = "wcc";
    rev = "503f6dfed71e5907e875e62bdf87905c6bce50b5";
    sha256 = "sha256-aPeU+bsNqd7JE/Wr/3w14+qaX7th9mFxMrTLnWJ8RQ8=";
    fetchSubmodules = true;
  };

  buildInputs = [ capstone libbfd libelf libiberty readline ];

  postPatch = ''
    sed -i src/wsh/include/libwitch/wsh.h src/wsh/scripts/INDEX \
      -e "s#/usr/share/wcc#$out/share/wcc#"

    sed -i -e '/stropts.h>/d' src/wsh/include/libwitch/wsh.h
  '';

  installFlags = [ "DESTDIR=$(out)" ];

  preInstall = ''
    mkdir -p $out/usr/bin
  '';

  postInstall = ''
    mv $out/usr/* $out
    rmdir $out/usr
    mkdir -p $out/share/man/man1
    cp doc/manpages/*.1 $out/share/man/man1/
  '';

  postFixup = ''
    # not detected by patchShebangs
    substituteInPlace $out/bin/wcch --replace '#!/usr/bin/wsh' "#!$out/bin/wsh"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/endrazine/wcc";
    description = "Witchcraft compiler collection: tools to convert and script ELF files";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ orivej ];
  };
}
