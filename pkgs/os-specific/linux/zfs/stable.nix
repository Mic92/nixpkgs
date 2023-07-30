{ callPackage
, kernel ? null
, stdenv
, linuxKernel
, removeLinuxDRM ? false
, fetchpatch
, ...
} @ args:

let
  stdenv' = if kernel == null then stdenv else kernel.stdenv;
in
callPackage ./generic.nix args {
  # check the release notes for compatible kernels
  kernelCompatible =
    if stdenv'.isx86_64 || removeLinuxDRM
    then kernel.kernelOlder "6.4"
    else kernel.kernelOlder "6.2";
  latestCompatibleLinuxPackages = linuxKernel.packages.linux_6_1;
  extraPatches = [
    (fetchpatch {
      name = "musl.patch";
      url = "https://github.com/openzfs/zfs/commit/1f19826c9ac85835cbde61a7439d9d1fefe43a4a.patch";
      sha256 = "XEaK227ubfOwlB2s851UvZ6xp/QOtYUWYsKTkEHzmo0=";
    })
  ];

  # this package should point to the latest release.
  version = "2.1.14";

  sha256 = "sha256-RVAoZbV9yclGuN+D37SB6UCRFbbLEpBoyrQOQCVsQwE=";
}
