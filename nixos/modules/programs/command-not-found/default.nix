{ stdenv, rustPlatform, pkgconfig, sqlite
, dbPath ? "/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite" }:

rustPlatform.buildRustPackage {
  name = "command-not-found";
  src = ./rust;
  postConfigure = ''
    substituteInPlace src/config.rs \
      --replace '@DB_PATH@' '${dbPath}' \
      --replace '@NIX_SYSTEM@' '${stdenv.system}' \
  '';
  postInstall = ''
    strip $out/bin/command-not-found
  '';
  buildInputs = [ sqlite ];
  nativeBuildInputs = [ pkgconfig ];
  cargoSha256 = "0hmcn3f00r4k3zswqx2ls5nccn0bz7r8ifhgfa4g5gqrlsp6ib0b";

}
