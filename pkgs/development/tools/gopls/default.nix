{ stdenv, go, buildGoModule, fetchgit, makeWrapper }:

buildGoModule rec {
  pname = "gopls";
  version = "0.4.3";

  src = fetchgit {
    rev = "gopls/v${version}";
    url = "https://go.googlesource.com/tools";
    sha256 = "1r670c7p63l0fhx671r3mb1jgvvfv1382079fv59z07j5j5hizbc";
  };

  subPackages = [ "." ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/gopls \
      --suffix PATH : "${stdenv.lib.getBin go}"
  '';

  modRoot = "gopls";
  allowGoReference = true;
  vendorSha256 = "1xdvkdkvk7a32jspzjcgxkfdn78d2zm53wxmc9c4sqysxsgy6lbw";

  meta = with stdenv.lib; {
    description = "Official language server for the Go language";
    homepage = "https://github.com/golang/tools/tree/master/gopls";
    license = licenses.bsd3;
    maintainers = with maintainers; [ mic92 zimbatm ];
  };
}
