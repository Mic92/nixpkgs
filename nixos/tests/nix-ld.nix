import ./make-test-python.nix ({ lib, pkgs, ...} :
{
  name = "nix-ld";
  nodes.machine = { pkgs, ... }: {
    programs.nix-ld.enable = true;
    environment.systemPackages = [
      (pkgs.runCommand "patched-hello" {} ''
        install -D -m755 ${pkgs.hello}/bin/hello $out/bin/hello
        patchelf $out/bin/hello --set-interpreter $(cat ${pkgs.nix-ld}/nix-support/ldpath)
      '')
    ];
  };
  testScript = ''
    start_all()
    out = machine.succeed("hello")
    assert out == "Hello, world!\n", f"hello output was: '{out}', expected: Hello, world!"
    machine.succeed("/run/current-system/sw/share/nix-ld/lib/ld.so --version >&2")
 '';
})
