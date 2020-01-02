{ stdenv, buildPythonPackage, fetchPypi, requests, pytest }:

buildPythonPackage rec {
  pname = "fritzconnection";
  version = "1.2.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1f5nrvadhxbsbzb765hzhlvy1vjzmcabfz1jm1p0l235lpnz8kxm";
  };

  propagatedBuildInputs = [ requests ];
  checkInputs = [ pytest ];

  meta = with stdenv.lib; {
    description = "Python-Tool to communicate with the AVM FritzBox using the TR-064 protocol";
    homepage = https://github.com/kbr/fritzconnection;
    license = licenses.mit;
    maintainers = with maintainers; [ dotlambda ];
  };
}
