with import ./. { };
let
  sdk = (
    pkgs.androidenv.composeAndroidPackages {
      #toolsVersion = android.versions.tools;
      #platformToolsVersion = android.versions.platformTools;
      buildToolsVersions = [ "33.0.2" ];
      #platformVersions = android.platforms;

      includeEmulator = false;
      includeSources = false;
      includeSystemImages = false;

      #systemImageTypes = [ ];
      abiVersions = [ "arm64-v8a" ];
      #cmakeVersions = [ ];

      includeNDK = true;
      ndkVersions = [ "26.1.10909125" ];
      useGoogleAPIs = false;
      useGoogleTVAddOns = false;
      includeExtras = [
        "extras;google;gcm"
        "extras;google;m2repository"
      ];
    }
  );
in
sdk.androidsdk
