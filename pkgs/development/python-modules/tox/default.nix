{ lib
, buildPythonPackage
, fetchPypi
, packaging
, pluggy
, py
, six
, virtualenv
, setuptools-scm
, toml
, tomli
, filelock
, pythonAtLeast
, pythonOlder
}:

buildPythonPackage rec {
  pname = "tox";
  version = "3.26.0";

  buildInputs = [ setuptools-scm ];
  propagatedBuildInputs = [ packaging pluggy py six virtualenv filelock ]
                          ++ lib.optional (pythonAtLeast "3.7" && pythonOlder "3.11") tomli
                          ++ lib.optional (pythonOlder "3.7") toml;

  doCheck = false;

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-RPPDR8aMLGh5nX1E8YCPnTlvyKGlAMvGJCUzdceuEH4=";
  };

  meta = with lib; {
    description = "Virtualenv-based automation of test activities";
    homepage = "https://tox.readthedocs.io/";
    license = licenses.mit;
  };
}
