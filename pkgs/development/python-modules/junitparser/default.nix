{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  future,
  glibcLocales,
  lxml,
  unittestCheckHook,
}:

buildPythonPackage rec {
  pname = "junitparser";
  version = "2.8.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "weiwei";
    repo = "junitparser";
    rev = version;
    hash = "sha256-rhDP05GSWT4K6Z2ip8C9+e3WbvBJOwP0vctvANBs7cw=";
  };

  propagatedBuildInputs = [ future ];

  nativeCheckInputs = [
    unittestCheckHook
    lxml
    glibcLocales
  ];

  unittestFlagsArray = [ "-v" ];

  meta = with lib; {
    description = "Manipulates JUnit/xUnit Result XML files";
    mainProgram = "junitparser";
    license = licenses.asl20;
    homepage = "https://github.com/weiwei/junitparser";
    maintainers = with maintainers; [ multun ];
  };
}
