{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "sgmllib3k";
  version = "1.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "7868fb1c8bfa764c1ac563d3cf369c381d1325d36124933a726f29fcdaa812e9";
  };

  # no tests in pypi included
  doCheck = false;

  meta = with lib; {
    description = "Py3k port of sgmllib";
    # original homepage is down?
    homepage = "https://pypi.org/project/sgmllib3k/";
    license = licenses.bsd3;
    maintainers = [ maintainers.mic92 ];
  };
}
