{
  lib,
  asn1crypto,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  pytest-mock,
  pytestCheckHook,
  versioningit,
}:

buildPythonPackage rec {
  pname = "scramp";
  version = "1.4.5";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vj++d0yld6emWBF9ygFOXSVNFYzsrj3WAzLf4zzm144=";
  };

  build-system = [
    hatchling
    versioningit
  ];

  dependencies = [ asn1crypto ];

  nativeCheckInputs = [
    pytest-mock
    pytestCheckHook
  ];

  postPatch = ''
    # Upstream uses versioningit to set the version
    sed -i "/versioningit >=/d" pyproject.toml
    sed -i '/^name =.*/a version = "${version}"' pyproject.toml
    sed -i "/dynamic =/d" pyproject.toml
  '';

  pythonImportsCheck = [ "scramp" ];

  disabledTests = [ "test_readme" ];

  meta = {
    description = "Implementation of the SCRAM authentication protocol";
    homepage = "https://github.com/tlocke/scramp";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
