{ stdenv
, lib
, buildGoPackage
, go
, makeWrapper
, nix-prefetch-git
, fetchFromGitHub
}:

buildGoPackage {
  pname = "vgo2nix";
  version = "unstable-2019-10-21";
  goPackagePath = "github.com/adisbladis/vgo2nix";

  nativeBuildInputs = [ makeWrapper ];

  src = fetchFromGitHub {
    owner = "adisbladis";
    repo = "vgo2nix";
    rev = "1288e3dbf23ed79cef237661225df0afa30f8510";
    sha256 = "1xcf2g4n38zbizgqhyrmh440bdg3yap6h9nr22dmgm5hsml6mdia";
  };

  goDeps = ./deps.nix;

  allowGoReference = true;

  postInstall = with stdenv; let
    binPath = lib.makeBinPath [ nix-prefetch-git go ];
  in ''
    wrapProgram $bin/bin/vgo2nix --prefix PATH : ${binPath}
  '';

  meta = with stdenv.lib; {
    description = "Convert go.mod files to nixpkgs buildGoPackage compatible deps.nix files";
    homepage = https://github.com/adisbladis/vgo2nix;
    license = licenses.mit;
    maintainers = with maintainers; [ adisbladis ];
  };

}
