# buildEnv creates a tree of symlinks to the specified paths.  This is
# a Rust reimplementation of the buildEnv functionality.

{
  buildPackages,
  runCommand,
  lib,
  rustPlatform,
  writeClosure,
}:

let
  buildenv-rust = rustPlatform.buildRustPackage {
    pname = "nix-buildenv";
    version = "0.1.0";
    
    src = ./.;
    
    cargoLock = {
      lockFile = ./Cargo.lock;
    };
    
    # Replace the @storeDir@ placeholder if needed
    postPatch = ''
      substituteInPlace src/main.rs \
        --replace-fail '"/nix/store"' '"${builtins.storeDir}"'
    '';
    
    meta = {
      description = "Rust implementation of Nix buildEnv";
      mainProgram = "nix-buildenv";
    };
  };
in

lib.makeOverridable (
  {
    name,

    # The manifest file (if any).  A symlink $out/manifest will be
    # created to it.
    manifest ? "",

    # The paths to symlink.
    paths,

    # Whether to ignore collisions or abort.
    ignoreCollisions ? false,

    # Whether to ignore outputs that are a single file instead of a directory.
    ignoreSingleFileOutputs ? false,

    # Whether to include closures of all input paths.
    includeClosures ? false,

    # If there is a collision, check whether the contents and permissions match
    # and only if not, throw a collision error.
    checkCollisionContents ? true,

    # The paths (relative to each element of `paths') that we want to
    # symlink (e.g., ["/bin"]).  Any file not inside any of the
    # directories in the list is not symlinked.
    pathsToLink ? [ "/" ],

    # The package outputs to include. By default, only the default
    # output is included.
    extraOutputsToInstall ? [ ],

    # Root the result in directory "$out${extraPrefix}", e.g. "/share".
    extraPrefix ? "",

    # Shell commands to run after building the symlink tree.
    postBuild ? "",

    # Additional inputs
    nativeBuildInputs ? [ ], # Handy e.g. if using makeWrapper in `postBuild`.
    buildInputs ? [ ],

    passthru ? { },
    meta ? { },
    pname ? null,
    version ? null,
  }:
  let
    chosenOutputs = map (drv: {
      paths =
        # First add the usual output(s): respect if user has chosen explicitly,
        # and otherwise use `meta.outputsToInstall`. The attribute is guaranteed
        # to exist in mkDerivation-created cases. The other cases (e.g. runCommand)
        # aren't expected to have multiple outputs.
        (
          if
            (!drv ? outputSpecified || !drv.outputSpecified) && drv.meta.outputsToInstall or null != null
          then
            map (outName: drv.${outName}) drv.meta.outputsToInstall
          else
            [ drv ]
        )
        # Add any extra outputs specified by the caller of `buildEnv`.
        ++ lib.filter (p: p != null) (builtins.map (outName: drv.${outName} or null) extraOutputsToInstall);
      priority = drv.meta.priority or lib.meta.defaultPriority;
    }) paths;

    pathsForClosure = lib.pipe chosenOutputs [
      (map (p: p.paths))
      lib.flatten
      (lib.remove null)
    ];
  in
  runCommand name
    (
      let
        pkgsJson = builtins.toJSON chosenOutputs;
      in
      {
        inherit
          manifest
          ignoreCollisions
          checkCollisionContents
          ignoreSingleFileOutputs
          passthru
          meta
          extraPrefix
          postBuild
          buildInputs
          ;
        pathsToLink = builtins.concatStringsSep " " pathsToLink;
        nativeBuildInputs = nativeBuildInputs ++ [ buildenv-rust ];
        pkgs = pkgsJson;
        extraPathsFrom = lib.optional includeClosures (writeClosure pathsForClosure);
        preferLocalBuild = true;
        allowSubstitutes = false;
        # XXX: The size is somewhat arbitrary
        passAsFile = if builtins.stringLength pkgsJson >= 128 * 1024 then [ "pkgs" ] else [ ];
        
        # Set up environment variables
        storeDir = builtins.storeDir;
      }
      // lib.optionalAttrs (pname != null) {
        inherit pname;
      }
      // lib.optionalAttrs (version != null) {
        inherit version;
      }
    )
    ''
      # Run the Rust buildenv implementation
      nix-buildenv
      eval "$postBuild"
    ''
)