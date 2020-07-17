{ ripgrep, gitAndTools, fzf, makeWrapper, vim_configurable, vimPlugins, fetchFromGitHub, writeTextDir
, stdenv, runCommandNoCC, remarshal, spacevim_config ? import ./init.nix }:
with stdenv;
let
  # Once https://github.com/NixOS/nixpkgs/pull/75584 is merged we can use the TOML generator
  toTOML = name: value: runCommandNoCC name {
    nativeBuildInputs = [ remarshal ];
    value = builtins.toJSON value;
    passAsFile = [ "value" ];
  } ''
    mkdir $out
    json2toml "$valuePath" "$out/${name}"
  '';

  vim-customized = vim_configurable.customize {
    name = "vim";
    # Not clear at the moment how to import plugins such that
    # SpaceVim finds them and does not auto download them to
    # ~/.cache/vimfiles/repos
    vimrcConfig.packages.myVimPackage = with vimPlugins; { start = [ ]; };
  };
  spacevimdir = toTOML "init.toml" spacevim_config;
in mkDerivation {
  pname = "spacevim";
  version = "unstable-2020-07-16";
  src = fetchFromGitHub {
    owner = "SpaceVim";
    repo = "SpaceVim";
    rev = "c937c0e2fd37207c36c8c5e53b36c41d7222fee6";
    sha256 = "141fl5g6i2h72dk5121v3mc0bwb812hd8qa5qw83jyz9q20jcsgn";
  };

  nativeBuildInputs = [ makeWrapper vim-customized];
  buildInputs = [ vim-customized ];

  buildPhase = ''
    # generate the helptags
    vim -u NONE -c "helptags $(pwd)/doc" -c q
  '';

  patches = [ ./helptags.patch ];

  installPhase = ''
    mkdir -p $out/bin

    cp -r $(pwd) $out/SpaceVim

    # trailing slash very important for SPACEVIMDIR
    makeWrapper "${vim-customized}/bin/vim" "$out/bin/spacevim" \
        --add-flags "-u $out/SpaceVim/vimrc" --set SPACEVIMDIR "${spacevimdir}/" \
        --prefix PATH : ${lib.makeBinPath [ fzf gitAndTools.git ripgrep]}
  '';

  meta = with stdenv.lib; {
    description = "SpaceVim - Modern Vim distribution";
    longDescription = ''
      SpaceVim is a distribution of the Vim editor that’s inspired by spacemacs.
    '';
    homepage = "https://spacevim.org/";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.fzakaria ];
    platforms = platforms.all;
  };
}
