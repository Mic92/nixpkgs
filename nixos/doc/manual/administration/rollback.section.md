# Rolling Back Configuration Changes {#sec-rollback}

After running `nixos-rebuild` to switch to a new configuration, you may
find that the new configuration doesn't work very well. In that case,
there are several ways to return to a previous configuration.

First, the GRUB boot manager allows you to boot into any previous
configuration that hasn't been garbage-collected. These configurations
can be found under the GRUB submenu "NixOS - All configurations". This
is especially useful if the new configuration fails to boot. After the
system has booted, you can make the selected configuration the default
for subsequent boots:

```ShellSession
# /run/current-system/bin/switch-to-configuration boot
```

Second, you can switch to the previous configuration in a running
system:

```ShellSession
# nixos-rebuild switch --rollback
```

This is equivalent to running:

```ShellSession
# /nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
```

where `N` is the number of the NixOS system configuration. To get a
list of the available configurations, do:

```ShellSession
$ ls -l /nix/var/nix/profiles/system-*-link
...
lrwxrwxrwx 1 root root 78 Aug 12 13:54 /nix/var/nix/profiles/system-268-link -> /nix/store/202b...-nixos-13.07pre4932_5a676e4-4be1055
```

Third, you can switch to a specific configuration in a running system:
```ShellSession
# nixos-rebuild switch --generation N
```

This is equivalent to running:
```ShellSession
# /nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
```
To get a list of available generations, you can run
```ShellSession
$ nixos-rebuild list-generations
Generation  NixOS version           Kernel  Build-date
...
99          21.03.20210103.44ac7cb  5.9.9   Sun 2021-01-03 21:00:00
100         21.03.20210104.19ab7f1  5.10.4  Mon 2021-01-04 20:21:22  (current)
```
