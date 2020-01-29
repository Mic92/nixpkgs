{ lib
, buildPythonPackage
, fetchPypi
, icalendar
, dulwich
, defusedxml
, jinja2
}:

buildPythonPackage rec {
  pname = "xandikos";
  version = "0.1.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1b2f75d8c49ef4bd0d28a90175f6e99740876c429e6892aa96dc2e0b540a254e";
  };

  # # Package conditions to handle
  # # might have to sed setup.py and egg.info in patchPhase
  # # sed -i "s/<package>.../<package>/"
  # dulwich>=0.19.1
  propagatedBuildInputs = [
    icalendar
    dulwich
    defusedxml
    jinja2
  ];

  meta = with lib; {
    description = "Lightweight CalDAV/CardDAV server";
    homepage = https://www.xandikos.org/;
    license = licenses.gpl3;
    maintainers = [ maintainers.mic92 ];
  };
}
