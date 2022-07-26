{ fetchFromGitHub, lib, stdenv, wxGTK30, freeimage, cmake, zziplib, libGLU, libGL, boost,
  pkg-config, libuuid, openal, ogre, ois, curl, gtk2, mygui, unzip,
  angelscript, ogrepaged, mysocketw, libxcb, fmt, rapidjson, makeWrapper
  }:

stdenv.mkDerivation rec {
  version = "2022.04";
  pname = "rigsofrods";

  src = fetchFromGitHub {
    owner = "RigsOfRods";
    repo = "rigs-of-rods";
    rev = version;
    sha256 = "sha256-QExh7ujPvKL9UOByNKvhKgmhpmAOt+OsoZeH50Brww0=";
  };

  NIX_CFLAGS_COMPILE = [ "-Wno-format-security" ];

  # FIXME, we get this error from RunRoR:
  # InvalidParametersException: Parameter called worldViewProj does not exist.
  # in GpuProgramParameters::_findNamedConstantDefinition at /build/source/OgreMain/src/OgreGpuProgramParams.cpp (line 1673)
  postInstall = ''
     substituteInPlace $out/plugins.cfg \
       --replace "PluginFolder=lib" "PluginFolder=${ogre}/lib/OGRE"
     mkdir rigsofrods
     mv $out/* rigsofrods
     mkdir -p $out/{lib,bin}
     mv rigsofrods $out/lib
     makeWrapper $out/lib/rigsofrods/RunRoR $out/bin/RunRoR \
       --chdir "$out/lib/rigsofrods"
  '';

  nativeBuildInputs = [ cmake pkg-config unzip makeWrapper ];
  buildInputs = [ fmt rapidjson wxGTK30 freeimage zziplib libGLU libGL boost
    libuuid openal ogre ois curl gtk2 mygui angelscript
    ogrepaged mysocketw libxcb ];

  meta = with lib; {
    description = "3D simulator game where you can drive, fly and sail various vehicles";
    homepage = "http://rigsofrods.sourceforge.net/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ raskin ];
    platforms = platforms.linux;
    hydraPlatforms = [];
  };
}
