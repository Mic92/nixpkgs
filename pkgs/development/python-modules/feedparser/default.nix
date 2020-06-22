{ stdenv
, buildPythonPackage
, fetchFromGitHub
, pythonOlder
, sgmllib3k
}:

buildPythonPackage rec {
  pname = "feedparser";
  version = "6.0.1b3";

  disabled = pythonOlder "3.5";

  src = fetchFromGitHub {
    owner = "kurtmckee";
    repo = "feedparser";
    rev = "530bb8cfdfaf007917ab65a79e54edf7136bd9f8";
    sha256 = "0mr1p9a22js4g4sbkpvb5xc5rr6k48hzm777w5w901m8jimcmh7s";
  };

  propagatedBuildInputs = [
    sgmllib3k
  ];

  # lots of networking failures
  doCheck = false;

  meta = with stdenv.lib; {
    homepage = "https://github.com/kurtmckee/feedparser";
    description = "Universal feed parser";
    license = licenses.bsd2;
    maintainers = with maintainers; [ domenkozar ];
  };
}
