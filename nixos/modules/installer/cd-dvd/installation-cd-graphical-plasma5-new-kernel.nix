{ pkgs, ... }:

{
  imports = [
    ./installation-cd-graphical-plasma5.nix
    ../../profiles/new-kernel.nix
  ];
}
