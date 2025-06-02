{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  openssh,
  openssl,
  fetchpatch2
}:

buildGoModule rec {
  pname = "ssh-tpm-agent";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "Foxboron";
    repo = "ssh-tpm-agent";
    tag = "v${version}";
    hash = "sha256-CSxZctiQ/d4gzCUtfx9Oetb8s0XpHf3MPH/H0XaaVgg=";
  };

  proxyVendor = true;

  patches = [
    # https://github.com/Foxboron/ssh-tpm-agent/pull/94
    (fetchpatch2 {
      url = "https://github.com/Foxboron/ssh-tpm-agent/commit/5546f4a934f010bee4ef8cd0d7920132ed09308a.patch";
      hash = "sha256-F1hWJF6dlTpgRBuM2PgIpv63KSBiClBV+m1zGHFD/ac=";
    })
  ];

  vendorHash = "sha256-84ZB1B+RczJS08UToCWvvVfWrD62IQxy0XoBwn+wBkc=";

  buildInputs = [
    openssl
  ];

  nativeCheckInputs = [
    openssh
  ];

  # disable broken tests, see https://github.com/NixOS/nixpkgs/pull/394097
  preCheck = ''
    rm cmd/scripts_test.go
    substituteInPlace internal/keyring/keyring_test.go --replace-fail ENOKEY ENOENT
    substituteInPlace internal/keyring/threadkeyring_test.go --replace-fail ENOKEY ENOENT
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "SSH agent with support for TPM sealed keys for public key authentication";
    homepage = "https://github.com/Foxboron/ssh-tpm-agent";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ sgo ];
    mainProgram = "ssh-tpm-agent";
  };
}
