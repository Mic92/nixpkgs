{ stdenv, fetchFromGitHub, curl, libzip, pkgconfig, fetchpatch }:

stdenv.mkDerivation rec {
  pname = "tldr";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "tldr-pages";
    repo = "tldr-cpp-client";
    rev = "v${version}";
    sha256 = "10ylpiqc06p0qpma72vwksd7hd107s0vlx9c6s9rz4vc3i274lb6";
  };

  patches = [
    # fish support
    (fetchpatch {
      url = "https://github.com/tldr-pages/tldr-cpp-client/commit/7e17a596043675e7d95c4d86ea33b3fbe3b50ebf.patch";
      sha256 = "044yj55nq0lcmalghfv05akqldbznfl9bb83pyzc2k3vh250fgyp";
    })
  ];

  buildInputs = [ curl libzip ];
  nativeBuildInputs = [ pkgconfig ];

  makeFlags = ["CC=cc" "LD=cc" "CFLAGS="];

  installFlags = [ "PREFIX=$(out)" ];

  postInstall = ''
    install -D autocomplete/complete.zsh "$out/share/zsh/vendor_completions/_tldr"
    install -D autocomplete/complete.bash "$out/etc/bash_completion.d/tldr.sh"
    install -D autocomplete/complete.fish "$out/share/fish/vendor_completions.d/tldr.fish"
  '';

  meta = with stdenv.lib; {
    description = "Simplified and community-driven man pages";
    longDescription = ''
      tldr pages gives common use cases for commands, so you don't need to hunt
      through a man page for the correct flags.
    '';
    homepage = http://tldr-pages.github.io;
    license = licenses.mit;
    maintainers = with maintainers; [ taeer carlosdagos ];
    platforms = platforms.all;
  };
}
