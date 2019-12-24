{ stdenv, callPackage, fetchurl }:
let
  version = "2019-11-17";

  # fetch hashes by running `print-hashes.sh 1.38.0`
  hashes = {
    i686-unknown-linux-gnu = "ea61b9a64d2298ee8bd56aba29656d39b4716c0a2779286d0a33e8540594591d";
    x86_64-unknown-linux-gnu = "14aeea32786fed4eef551cfacc0fe6710c8d9b5e3667448fb9101406ca035240";
    arm-unknown-linux-gnueabihf = "3ac8afa548f2c6deae8d03d7b17d6a00a31df7e2a6b499809fae0ddb45466abf";
    armv7-unknown-linux-gnueabihf = "4a57697e2b12465d6ad714d16bd07b5fdd3ad172b3df0e1e3457000d8ae8cc95";
    aarch64-unknown-linux-gnu = "229f4ad4f042dd31e3748744d28bceb65077918bbd2c0f7f20e74f659f38b02e";
    i686-apple-darwin = "65c4d069c4ba2f3357dcb96ae072ae0c39a1fefc4266eb27ecb28f01b36a9200";
    x86_64-apple-darwin = "bcbe00a76f4ed039b8ce33ccf6a632d7b9d8a1f9a5c16b95687fcda315ae2660";
  };

  platform =
    if stdenv.hostPlatform.system == "i686-linux"
    then "i686-unknown-linux-gnu"
    else if stdenv.hostPlatform.system == "x86_64-linux"
    then "x86_64-unknown-linux-gnu"
    else if stdenv.hostPlatform.system == "armv7l-linux"
    then "armv7-unknown-linux-gnueabihf"
    else if stdenv.hostPlatform.system == "aarch64-linux"
    then "aarch64-unknown-linux-gnu"
    else if stdenv.hostPlatform.system == "i686-darwin"
    then "i686-apple-darwin"
    else if stdenv.hostPlatform.system == "x86_64-darwin"
    then "x86_64-apple-darwin"
    else throw "missing bootstrap url for platform ${stdenv.hostPlatform.system}";

  src = fetchurl {
     url = "https://static.rust-lang.org/dist/${version}/rust-nightly-${platform}.tar.gz";
     sha256 = hashes."${platform}";
  };
in callPackage ./binary.nix  rec {
  inherit version src platform;
  versionType = "bootstrap";
}
