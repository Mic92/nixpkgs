{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bcachefs is supported since 6.7.
  # Move this to nixos/modules/profiles/base.nix, once we update to a new lts kernel.
  boot.supportedFilesystems.bcachefs = true;
}

