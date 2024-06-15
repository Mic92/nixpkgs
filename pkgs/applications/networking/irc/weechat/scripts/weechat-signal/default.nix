{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  qrcode,
}:

buildPythonPackage {
  pname = "weechat-signal";
  version = "0-unstable-2024-04-21";

  src = fetchFromGitHub {
    owner = "thefinn93";
    repo = "signal-weechat";
    rev = "71889795e1e195c8db578a4ee416e3ecd84e35e4";
    hash = "sha256-WB09SsC4tuA/49iDaM9k2RWcmZqmIp/4Tb02hyWyFX0=";
  };

  propagatedBuildInputs = [
    qrcode
  ];

  passthru.scripts = [ "signal.py" ];

  dontBuild = true;
  doCheck = false;

  format = "other";

  installPhase = ''
    mkdir -p $out/share $out/bin
    cp signal.py $out/share/signal.py
  '';

  dontPatchShebangs = true;
  postFixup = ''
    patchPythonScript $out/share/signal.py
  '';

  meta = with lib; {
    description = "Use signal in weechat";
    homepage = "https://github.com/thefinn93/signal-weechat";
    license = licenses.isc;
    platforms = platforms.unix;
    maintainers = with maintainers; [ mic92 ];
  };
}
