{ lib
, fetchpatch
, kernel
, buildLinux
, fetchFromGitHub
, kernelPatches # must always be defined in bcachefs' all-packages.nix entry because it's also a top-level attribute supplied by callPackage
, argsOverride ? {}
, ...
} @ args:
buildLinux (args // {
  # NOTE: bcachefs-tools should be updated simultaneously to preserve compatibility
  version = "6.1.0-2022-12-29";
  modDirVersion = "6.1.0";

  src = fetchFromGitHub {
    owner = "koverstreet";
    repo = "bcachefs";
    rev = "8f064a4cb5c7cce289b83d7a459e6d8620188b37";
    sha256 = "sha256-UgWAbYToauAjGrgeS+o6N42/oW0roICJIoJlEAHBRPk=";
  };

  extraConfig = "BCACHEFS_FS m";

  extraMeta = {
    branch = "master";
    hydraPlatforms = []; # Should the testing kernels ever be built on Hydra?
    maintainers = with lib.maintainers; [ davidak chiiruno ];
    platforms = [ "x86_64-linux" ];
  };

} // (args.argsOverride or {}))
