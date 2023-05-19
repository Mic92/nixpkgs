{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sysdig;
in {
  options.programs.sysdig.enable = mkEnableOption (lib.mdDoc "sysdig");
  options.programs.sysdig.package = lib.mkPackageOptionMD config.boot.kernelPackages "sysdig" { };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sysdig ];
    boot.extraModulePackages = [ config.programs.sysdig.package ];
  };
}
