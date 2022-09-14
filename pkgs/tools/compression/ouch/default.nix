{ lib
, rustPlatform
, fetchFromGitHub
, help2man
, installShellFiles
, pkg-config
, bzip2
, xz
, zlib
, zstd
}:

rustPlatform.buildRustPackage rec {
  pname = "ouch";
  version = "2022-09-01";

  src = fetchFromGitHub {
    owner = "ouch-org";
    repo = pname;
    rev = "ff8619acb7c5ea92b17674421e7dc422b8ccbeb0";
    sha256 = "sha256-Av1+ib41XRsWoH/nMpzyfwetnKtswtXlAC1QXCbkweY=";
    #rev = version;
    #sha256 = "sha256-I9CgkYxcK+Ih9UlcYBa8QAZZsPvzPUK5ZUYKPxzgs38=";
  };

  cargoSha256 = "sha256-WZdUlbjIeDXD861QuSypOV6/Ofx0RA4qQxmIT1jquPk=";

  nativeBuildInputs = [ help2man installShellFiles pkg-config ];

  buildInputs = [ bzip2 xz zlib zstd ];

  buildFeatures = [ "zstd/pkg-config" ];

  postInstall = ''
    help2man $out/bin/ouch > ouch.1
    installManPage ouch.1

    completions=($releaseDir/build/ouch-*/out/completions)
    installShellCompletion $completions/ouch.{bash,fish} --zsh $completions/_ouch
  '';

  GEN_COMPLETIONS = 1;

  meta = with lib; {
    description = "A command-line utility for easily compressing and decompressing files and directories";
    homepage = "https://github.com/ouch-org/ouch";
    license = licenses.mit;
    maintainers = with maintainers; [ figsoda psibi ];
  };
}
