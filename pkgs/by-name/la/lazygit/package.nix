{
  lib,
  buildGo122Module,
  fetchFromGitHub,
  lazygit,
  testers,
}:
# Regression in go1.23 see https://github.com/jesseduffield/lazygit/issues/4002
buildGo122Module rec {
  pname = "lazygit";
  version = "0.45.2-unstable-2025-01-27";

  src = fetchFromGitHub {
    owner = "jesseduffield";
    repo = pname;
    rev =  "372282429833f29f114dd149a4d19078c33a9e5c";
    hash = "sha256-cwGzb1aCoiXQ83uQjffaTv/7Q+oUlhEA3nNVoYs2sos=";
  };

  vendorHash = null;
  subPackages = [ "." ];

  ldflags = [
    "-X main.version=${version}"
    "-X main.buildSource=nix"
  ];

  passthru.tests.version = testers.testVersion { package = lazygit; };

  meta = {
    description = "Simple terminal UI for git commands";
    homepage = "https://github.com/jesseduffield/lazygit";
    changelog = "https://github.com/jesseduffield/lazygit/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      Br1ght0ne
      equirosa
      khaneliman
      paveloom
      starsep
      sigmasquadron
    ];
    mainProgram = "lazygit";
  };
}
