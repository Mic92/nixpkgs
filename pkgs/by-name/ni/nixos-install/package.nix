{
  lib,
  substituteAll,
  runtimeShell,
  installShellFiles,
  nix,
  jq,
  nixos-enter,
  man,
  stdenv,
  util-linuxMinimal,
}:
substituteAll {
  name = "nixos-install";
  src = ./nixos-install.sh;

  inherit runtimeShell nix;

  nativeBuildInputs = [ installShellFiles ];

  path = lib.makeBinPath [
    jq
    nixos-enter
    man
    util-linuxMinimal
  ];

  dir = "bin";
  isExecutable = true;

  manbin = lib.getExe man;
  nixosInstallManpage = "${placeholder "out"}/share/man/man8/nixos-install.8";

  postInstall =
    ''
      installManPage ${./nixos-install.8}
    ''
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      $out/bin/nixos-install --help >/dev/null
    '';

  meta = {
    description = "Install bootloader and NixOS";
    homepage = "https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/in/nixos-install";
    license = lib.licenses.mit;
    mainProgram = "nixos-install";
  };
}
