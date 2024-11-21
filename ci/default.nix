let
  pinnedNixpkgs = builtins.fromJSON (builtins.readFile ./pinned-nixpkgs.json);
in
{
  system ? builtins.currentSystem,

  nixpkgs ? null,
}:
let
  nixpkgs' =
    if nixpkgs == null then
      builtins.fetchGit {
        url = "https://github.com/NixOS/nixpkgs";
        rev = pinnedNixpkgs.rev;
        shallow = true;
      }
    else
      nixpkgs;

  pkgs = import nixpkgs' {
    inherit system;
    config = { };
    overlays = [ ];
  };
in
{
  inherit pkgs;
  requestReviews = pkgs.callPackage ./request-reviews { };
  codeownersValidator = pkgs.callPackage ./codeowners-validator { };
  eval = pkgs.callPackage ./eval { };
}
