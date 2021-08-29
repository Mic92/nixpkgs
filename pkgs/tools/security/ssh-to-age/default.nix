{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "ssh-to-age";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "Mic92";
    repo = "ssh-to-age";
    rev = version;
    sha256 = "sha256-C0ccXsPNwuBTTWaX7LQ+JUj3RCP+sXpHoj+Ih/AreDA=";
  };

  vendorSha256 = "sha256-jiFPcdWnAk54RJv4mHB3A+5tqKzqitfsiRXYZLa3Gu0=";

  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';

  doCheck = true;

  meta = with lib; {
    description = "Convert ssh private keys in ed25519 format to age keys";
    homepage = "https://github.com/Mic92/ssh-to-age";
    license = licenses.mit;
    maintainers = with maintainers; [ mic92 ];
    platforms = platforms.unix;
  };
}
