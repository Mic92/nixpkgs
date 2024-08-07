{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pandas,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "pycatch22";
  version = "0.4.5";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "DynamicsAndNeuralSystems";
    repo = "pycatch22";
    rev = "refs/tags/v${version}";
    hash = "sha256-NvZrjOdC6rV4hwCuGcc2Br/VDhLwZcYpfnNvQpqU134=";
  };

  nativeBuildInputs = [ setuptools ];

  nativeCheckInputs = [ pandas ];

  # This packages does not have real tests
  # But we can run this file as smoketest
  checkPhase = ''
    runHook preCheck

    python tests/testing.py

    runHook postCheck
  '';

  pythonImportsCheck = [ "pycatch22" ];

  meta = with lib; {
    description = "Python implementation of catch22";
    homepage = "https://github.com/DynamicsAndNeuralSystems/pycatch22";
    changelog = "https://github.com/DynamicsAndNeuralSystems/pycatch22/releases/tag/v${version}";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ mbalatsko ];
  };
}
