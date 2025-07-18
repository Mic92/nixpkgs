{
  lib,
  argcomplete,
  buildPythonPackage,
  fetchPypi,
  jq,
  pytestCheckHook,
  pyyaml,
  setuptools-scm,
  replaceVars,
  tomlkit,
  xmltodict,
}:

buildPythonPackage rec {
  pname = "yq";
  version = "3.4.3";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-ulhqGm8wz3BbL5IgZxLfIoHNMgKAIQ57e4Cty48lbjs=";
  };

  patches = [
    (replaceVars ./jq-path.patch {
      jq = "${lib.getBin jq}/bin/jq";
    })
  ];

  nativeBuildInputs = [ setuptools-scm ];

  propagatedBuildInputs = [
    argcomplete
    pyyaml
    tomlkit
    xmltodict
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  enabledTestPaths = [ "test/test.py" ];

  pythonImportsCheck = [ "yq" ];

  meta = with lib; {
    description = "Command-line YAML/XML/TOML processor - jq wrapper for YAML, XML, TOML documents";
    homepage = "https://github.com/kislyuk/yq";
    license = licenses.asl20;
    maintainers = with maintainers; [
      womfoo
      SuperSandro2000
    ];
    mainProgram = "yq";
  };
}
