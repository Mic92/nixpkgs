# Running Tests interactively {#sec-running-nixos-tests-interactively}

The test itself can be run interactively. This is particularly useful
when developing or debugging a test:

```ShellSession
$ nix-build . -A nixosTests.login.driverInteractive
$ ./result/bin/nixos-test-driver
[...]
>>>
```

You can then take any Python statement, e.g.

```py
>>> start_all()
>>> test_script()
>>> machine.succeed("touch /tmp/foo")
>>> print(machine.succeed("pwd")) # Show stdout of command
```

The function `test_script` executes the entire test script and drops you
back into the test driver command line upon its completion. This allows
you to inspect the state of the VMs after the test (e.g. to debug the
test script).

## Shell access

The function `<yourmachine>.shell_interact()` gives access to a shell running
inside the guest. Replace `<yourmachine` with the name of a virtual machine
defined in the the test i.e. `machine`:

```py
>>> machine.shell_interact()
machine: Terminal is ready (there is no initial prompt):
$ hostname
machine
```

Note that this shell will not have the correct terminal size set due to running inside an interactive python repl and output of the nixos machines will overwrite
user input. An alternative is to proxy the guest shell to a local tcp server
that takes its input from an otherwise unused terminal.

For that first start a TCP server in one terminal:

```ShellSession
$ socat 'READLINE,PROMPT=$ ' tcp-listen:4444,reuseaddr
```

In the terminal that runs the nixos test driver, you can than connect to this
server like this:

```py
>>> machine.shell_interact("tcp:127.0.0.1:4444")
```

After connecting you should be able to type into commands in the terminal `socat` that runs socat.

## Reuse VM state {#sec-nixos-test-reuse-vm-state}

You can re-use the VM states coming from a previous run by setting the
`--keep-vm-state` flag.

```ShellSession
$ ./result/bin/nixos-test-driver --keep-vm-state
```

The machine state is stored in the `$TMPDIR/vm-state-machinename`
directory.

## Interactive-only test configuration {#sec-nixos-test-interactive-configuration}

The `.driverInteractive` attribute combines the regular test configuration with
definitions from the [`interactive` submodule](#test-opt-interactive). This gives you
a more usable, graphical, but slightly different configuration.

You can add your own interactive-only test configuration by adding extra
configuration to the [`interactive` submodule](#test-opt-interactive).

To interactively run only the regular configuration, build the `<test>.driver` attribute
instead, and call it with the flag `result/bin/nixos-test-driver --interactive`.
