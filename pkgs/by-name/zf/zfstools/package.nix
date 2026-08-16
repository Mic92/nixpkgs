{
  lib,
  stdenv,
  python3Packages,
  fetchFromGitHub,
  zfs,
  freebsd,
}:

python3Packages.buildPythonApplication {
  pname = "zfstools";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Mic92";
    repo = "zfstools-py";
    rev = "971770144309cf7f1d49316d1341396040992e1a";
    hash = "sha256-JYXqAlmZQUB5LVsSvQzjKDIQsz2oZgyOLOErTy8p4Bg=";
  };

  build-system = [ python3Packages.hatchling ];

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ (if stdenv.hostPlatform.isFreeBSD then freebsd.zfs else zfs) ]}"
  ];

  nativeCheckInputs = [ python3Packages.pytestCheckHook ];

  meta = {
    description = "OpenSolaris-compatible auto-snapshotting script for ZFS";
    homepage = "https://github.com/Mic92/zfstools-py";
    license = lib.licenses.bsd2;
    mainProgram = "zfs-auto-snapshot";
    platforms = lib.platforms.linux ++ lib.platforms.freebsd;
  };
}
