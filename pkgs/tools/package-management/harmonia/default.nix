{ lib
, boost
, fetchFromGitHub
, libsodium
, nix
, pkg-config
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "harmonia";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "helsinki-systems";
    repo = pname;
    rev = "refs/tags/${pname}-v${version}";
    hash = "sha256-7hsq6Sv06UcIjjlZTFlsYWDfGrc9u77OAr25SjnvZ4A=";
  };

  cargoHash = "sha256-f6b8l/VxRyBm29vkvKKdCxFh1EaNZSZyUsoMeAEsRR4=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    boost
    libsodium
    nix
  ];

  meta = with lib; {
    description = "Nix binary cache";
    homepage = "https://github.com/helsinki-systems/harmonia";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
