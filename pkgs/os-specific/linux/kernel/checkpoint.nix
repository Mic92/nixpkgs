{
  lib,
  buildPackages,
}:

let
  inherit (buildPackages) rsync;
in

{
  /*
    Prepare a kernel derivation for checkpoint-based incremental builds.

    Runs the full kernel build (unpack → patch → configure → build) but
    captures the source tree and the kbuild output directory instead of
    installing.  The result is passed to `mkKernelCheckpointBuild` for
    fast incremental rebuilds.

    What gets saved:
      $out/sources/  – post-patch source tree (reference for diffing)
      $out/build/    – complete $buildRoot with .o, .cmd, vmlinux, …
      $out/sourceRoot – absolute source path (for .cmd fixup)
      $out/buildRoot  – absolute build  path (for .cmd fixup)

    Usage:
      checkpoint = kernelCheckpointTools.prepareKernelCheckpoint pkgs.linux;
  */
  prepareKernelCheckpoint =
    drv:
    drv.overrideAttrs (old: {
      outputs = [ "out" ];
      name = drv.name + "-kernelCheckpoint";

      # After configurePhase, CWD = $buildRoot (the out-of-tree build dir).
      # Snapshot the source tree (one level up, excluding build/) so we can
      # diff against it later.
      preBuild =
        (old.preBuild or "")
        + ''
          checkpointSourceRoot="$(dirname "$buildRoot")"
          mkdir -p "$out/sources"
          ${rsync}/bin/rsync -a --exclude='/build/' \
            "$checkpointSourceRoot/" "$out/sources/"

          # Record the absolute paths so mkKernelCheckpointBuild can fixup
          # kbuild .cmd files when the sandbox path changes between builds.
          echo "$checkpointSourceRoot" > "$out/sourceRoot"
          echo "$buildRoot"            > "$out/buildRoot"
        '';

      # Replace the normal install with a snapshot of the build directory.
      # This preserves every kbuild artifact needed for incremental builds:
      # .o files, .cmd dependency trackers, generated headers, vmlinux, etc.
      installPhase = ''
        mkdir -p "$out/build"
        cp -a . "$out/build/"
      '';

      dontFixup = true;
      doInstallCheck = false;
      doDist = false;
    });

  /*
    Build a kernel incrementally from a previously prepared checkpoint.

    Restores the checkpoint's build artifacts into the current build tree
    and lets kbuild's native incremental compilation rebuild only the
    files whose sources changed.  This turns multi-hour kernel builds
    into minutes when only a few files differ.

    The function:
      1. Diffs the current (possibly patched) sources against the checkpoint.
      2. Restores the checkpoint's source tree and build directory.
      3. Applies the source diff — only touched files get a new mtime.
      4. Fixes up absolute sandbox paths inside kbuild .cmd files.
      5. Re-links the current .config and runs `make oldconfig`.
      6. Hands off to the normal build phase — kbuild recompiles only
         what changed.

    Usage:
      checkpoint = kernelCheckpointTools.prepareKernelCheckpoint pkgs.linux;
      modified   = pkgs.linux.overrideAttrs (old: { src = ./my-tree; });
      fast       = kernelCheckpointTools.mkKernelCheckpointBuild modified checkpoint;
  */
  mkKernelCheckpointBuild =
    drv: checkpoint:
    drv.overrideAttrs (old: {
      preBuild =
        (old.preBuild or "")
        + ''
          checkpointSourceRoot="$(dirname "$buildRoot")"

          # ── 1. Compute source diff ──────────────────────────────────────
          #    Diff the checkpoint's sources against the current (post-patch)
          #    sources.  Exit code 1 = differences found, 0 = identical.
          sourceDiffFile=$(mktemp)
          set +e
          diff -urN \
            ${checkpoint}/sources/ \
            "$checkpointSourceRoot/" \
            > "$sourceDiffFile"
          diffExit=$?
          set -e

          if [ "$diffExit" -gt 1 ]; then
            echo "diff failed with exit code $diffExit"
            exit 1
          fi

          # ── 2. Restore build directory from checkpoint ──────────────────
          #    CWD is $buildRoot.  Wipe the freshly-configured build dir
          #    and replace it with the checkpoint's compiled artifacts.
          shopt -s dotglob
          rm -rf -- *
          ${rsync}/bin/rsync -a ${checkpoint}/build/ ./
          chmod -R u+w .
          shopt -u dotglob

          # ── 3. Restore source tree and apply diff ───────────────────────
          #    Replace the source tree with the checkpoint's snapshot, then
          #    apply the diff.  Only files mentioned in the diff get a new
          #    mtime, which is what tells kbuild to recompile them.
          (
            cd "$checkpointSourceRoot"
            ${rsync}/bin/rsync -a --delete --exclude='/build/' \
              ${checkpoint}/sources/ ./
            chmod -R u+w .

            if [ "$diffExit" -eq 1 ]; then
              echo "Applying source diff to trigger incremental rebuild…"
              patch -p1 --no-backup-if-mismatch < "$sourceDiffFile"
            else
              echo "Sources identical to checkpoint — pure config/flag rebuild."
            fi
          )

          # ── 4. Fix up kbuild .cmd paths ─────────────────────────────────
          #    .cmd files record the absolute compile commands.  If the build
          #    sandbox path differs between the checkpoint derivation and this
          #    one, every command looks "changed" and kbuild recompiles
          #    everything.  Rewrite the paths to prevent that.
          oldSourceRoot=$(cat ${checkpoint}/sourceRoot)
          oldBuildRoot=$(cat ${checkpoint}/buildRoot)

          if [ "$oldSourceRoot" != "$checkpointSourceRoot" ] \
              || [ "$oldBuildRoot" != "$buildRoot" ]; then
            echo "Fixing kbuild .cmd paths:"
            echo "  source: $oldSourceRoot -> $checkpointSourceRoot"
            echo "  build:  $oldBuildRoot  -> $buildRoot"
            find . -name '*.cmd' -print0 \
              | xargs -0 -r -P "''${NIX_BUILD_CORES:-1}" sed -i \
                  -e "s|$oldBuildRoot|$buildRoot|g" \
                  -e "s|$oldSourceRoot|$checkpointSourceRoot|g"
          fi

          # ── 5. Reconcile .config ────────────────────────────────────────
          #    The checkpoint may have been built with a different config.
          #    Re-link the current configfile and let oldconfig resolve any
          #    new or removed options.  kbuild will then compare .config
          #    against include/config/auto.conf and recompile affected files.
          rm -f .config
          ln -sv ${drv.configfile} .config
          make "''${makeFlags[@]}" oldconfig

          rm -f "$sourceDiffFile"
        '';
    });
}
