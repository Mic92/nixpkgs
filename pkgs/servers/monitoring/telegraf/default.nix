{ lib, buildGo120Module, fetchFromGitHub, nixosTests }:

# Upgraded from buildGo119Module to fix a test failure, switch back to
# buildGoModule once go1.20 is the default.
buildGo120Module rec {
  pname = "telegraf";
  version = "1.26.0";

  excludedPackages = "test";

  subPackages = [ "cmd/telegraf" ];

  src = fetchFromGitHub {
    owner = "influxdata";
    repo = "telegraf";
    rev = "v${version}";
    sha256 = "sha256-Huyjgo6UC9l6DVWBaKvN7ETxzsLDSaDC5Qx+gCR4LU4=";
  };

  vendorHash = "sha256-Z1xmtQ/Cs+7gdipEip/nkxARtuCYG1lZ59bGNhPjTcA=";
  proxyVendor = true;

  ldflags = [
    "-w" "-s" "-X main.version=${version}"
  ];

  passthru.tests = { inherit (nixosTests) telegraf; };

  meta = with lib; {
    description = "The plugin-driven server agent for collecting & reporting metrics";
    license = licenses.mit;
    homepage = "https://www.influxdata.com/time-series-platform/telegraf/";
    maintainers = with maintainers; [ mic92 roblabla timstott ];
  };
}
