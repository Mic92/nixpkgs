{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "tlx";
  version = "0.1.0-unstable-2026-11-11";

  src = fetchFromGitHub {
    owner = "tlaplus-x";
    repo = "tlx";
    rev = "8d5f082b0f0d922bf5999d9a8db00c70a4c1d261";
    hash = "sha256-GXKpkSTLtiJgwP4rSPoOjBbaqBK/3e7j+bbPKnKJP6s=";
  };

  cargoHash = "sha256-FUfIOOAXRAyGMjDDidAnijItDPVaxrF6l7zWCH3shCc=";

  cargoBuildFlags = [
    "--package"
    "tlx-cli"
  ];

  # The test suite checks the whole TLA+ corpus and takes far too long for a package build.
  doCheck = false;

  meta = {
    description = "Native-code model checker for TLA+ with TLC-compatible options and output";
    homepage = "https://github.com/tlaplus-x/tlx";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mic92 ];
    mainProgram = "tlx";
    platforms = lib.platforms.unix;
  };
}
