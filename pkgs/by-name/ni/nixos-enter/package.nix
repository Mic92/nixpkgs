{
  lib,
  substituteAll,
  runtimeShell,
  installShellFiles,
  util-linuxMinimal,
  man,
  stdenv,
}:
substituteAll {
  name = "nixos-enter";
  src = ./nixos-enter.sh;

  inherit runtimeShell;

  path = lib.makeBinPath [
    util-linuxMinimal
  ];

  dir = "bin";
  isExecutable = true;

  nativeBuildInputs = [ installShellFiles ];
  manbin = lib.getExe man;
  nixosEnterManpage = "${placeholder "out"}/share/man/man8/nixos-enter.8";

  postInstall = ''
    installManPage ${./nixos-enter.8}
    ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      $out/bin/nixos-enter --help >/dev/null
    ''}
  '';

  meta.mainProgram = "nixos-enter";
}
