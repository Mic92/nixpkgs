/* Create tests that run in the nix sandbox but get access to the host hardware

  The tests get access to /sys and optionally more, which lets them depend on hardware that is
  accessible to the host like GPUs.

  Example:
    makeImpureTest {
      name = "opencl";
      testedPackage = "mypackage"; # Or testPath = "mypackage.impureTests.opencl.testDerivation"

      sandboxPaths = [ "/sys" "/dev/dri" ]; # Defaults to ["/sys"]
      prepareRunCommands = ""; # (Optional) Setup for the runScript
      nixFlags = []; # (Optional) nix-build options for the runScript

      testScript = "...";
    }

  Add to a package:
    passthru.impureTests = { opencl = callPackage ./test.nix {}; };

  Run by building the run script, then executing it:
    $(nix-build -A mypackage.impureTests)

  Rerun an already cached test:
    $(nix-build -A mypackage.impureTests) --check
*/
{ lib
, stdenv
, writeShellScript

, name
, testedPackage ? null
, testPath ? "${testedPackage}.impureTests.${name}.testDerivation"
, sandboxPaths ? [ "/sys" ]
, prepareRunCommands ? ""
, nixFlags ? [ ]
, testScript
, ...
} @ args:

let
  sandboxPathsTests = builtins.map (path: "[[ ! -e '${path}' ]]") sandboxPaths;
  sandboxPathsTest = lib.concatStringsSep " || " sandboxPathsTests;
  sandboxPathsList = lib.concatStringsSep " " sandboxPaths;

  testDerivation = stdenv.mkDerivation (lib.recursiveUpdate
    {
      name = "test-run-${name}";

      requiredSystemFeatures = [ "nixos-test" ];

      buildCommand = ''
        mkdir -p $out

        if ${sandboxPathsTest}; then
          echo 'Run this test as *root* with `--option extra-sandbox-paths '"'${sandboxPathsList}'"'`'
          exit 1
        fi

        # Run test
        ${testScript}
      '';

      passthru.runScript = runScript;
    }
    (builtins.removeAttrs args [
      "lib"
      "stdenv"
      "writeShellScript"

      "name"
      "testedPackage"
      "testPath"
      "sandboxPaths"
      "prepareRunCommands"
      "nixFlags"
      "testScript"
    ])
  );

  runScript = writeShellScript "run-script-${name}" ''
    set -euo pipefail

    ${prepareRunCommands}

    /run/wrappers/bin/sudo nix-build --option extra-sandbox-paths '${sandboxPathsList}' ${lib.escapeShellArgs nixFlags} -A ${testPath} "$@"
  '';
in
# The main output is the run script, inject the derivation for the actual test
runScript.overrideAttrs (old: {
  passthru = { inherit testDerivation; };
})
