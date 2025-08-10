{
  callPackage,
  nixosTests,
  fetchpatch2,
  ...
}@args:

callPackage ./generic.nix args {
  # You have to ensure that in `pkgs/top-level/linux-kernels.nix`
  # this attribute is the correct one for this package.
  kernelModuleAttribute = "zfs_unstable";

  kernelMinSupportedMajorMinor = "4.18";
  kernelMaxSupportedMajorMinor = "6.15";

  # this package should point to a version / git revision compatible with the latest kernel release
  # IMPORTANT: Always use a tagged release candidate or commits from the
  # zfs-<version>-staging branch, because this is tested by the OpenZFS
  # maintainers.
  version = "2.3.3";
  # rev = "";

  tests = {
    inherit (nixosTests.zfs) unstable;
  };

  hash = "sha256-NXAbyGBfpzWfm4NaP1/otTx8fOnoRV17343qUMdQp5U=";

  extraPatches = [
    (fetchpatch2 {
      url = "https://github.com/openzfs/zfs/commit/fb7a8503bcfbbfe7b79d6c934062eee3c692b48b.patch";
      hash = "sha256-vRyymT9f6CEwI7/c0/eBY546HNogNWZqtA+DHl6zX1I=";
    })
  ];

  extraLongDescription = ''
    This is "unstable" ZFS, and will usually be a pre-release version of ZFS.
    It may be less well-tested and have critical bugs.
  '';
}
