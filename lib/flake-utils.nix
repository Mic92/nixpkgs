{ systems }:
rec {
  /* mapDefaultSystems using default supported systems
     Usage in a nix flake:
       {
         description = "Flake demo";

         inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

         outputs = nixpkgs.lib.mapDefaultSystems ({ self, nixpkgs }:
             {
               packages = {
                 hello = nixpkgs.legacyPackages.hello;
               };
               defaultPackage = self.packages.hello;
             }
           );
       }

     Type: mapDefaultSystems :: (attrset -> attrset) -> attrset

     Example:
       nixpkgs.lib.mapDefaultSystems ({self, nixpkgs}: {
         defaultPackage = inputs.nixpkgs.legacyPackages.hello;
       })
       => {
         defaultPackage = {
           aarch64-linux.hello = <<derivation /nix/store/...-hello-2.10.drv>>,
           ...
           x86_64-darwin.hello = <<derivation /nix/store/...-hello-2.10.drv>>,
           x86_64-linux.hello = <<derivation /nix/store/...-hello-2.10.drv>>,
         };
       }
  */
  mapDefaultSystems = mapSystems systems;

  /* Builds a map from <attr>=value to <attr>.<system>=value for each system,
     while converting flake inputs from <attr>.<system>=value to <attr>=value

     See `mapDefaultSystems` for a full example

     Type: mapSystems :: [string] -> (attrset -> attrset) -> attrset

     Example:
       mapSystems ["x86_64-linux"] ({ someAttrs }: { hello = someAttrs.packages.hello; }) { someAttrs = { packages.x86_64-linux.hello = 42; }}
       => { hello = { x86_64-linux = 42; }; }
  */
  mapSystems = systems: f: inputs:
    let
      op = attrs: system:
        let
          flattenInput = builtins.mapAttrs (_: attrs: if attrs ? ${system} then attrs.${system} else attrs);
          inputs' = builtins.mapAttrs (_: input: flattenInput input) inputs;
          ret = f inputs';
          op = attrs: key:
            attrs //
            {
              ${key} = (attrs.${key} or { }) // { ${system} = ret.${key}; };
            }
          ;
        in
        builtins.foldl' op attrs (builtins.attrNames ret);
    in
      builtins.foldl' op { } systems;
}
