{ pkgs ? import ../../.. { } }:

pkgs.mkShell {
  name = "buildenv-rust-dev";

  buildInputs = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];

  shellHook = ''
    echo "BuildEnv Rust Development Shell"
    echo "==============================="
    echo ""
    echo "Available commands:"
    echo "  cargo build              - Build the Rust implementation"
    echo "  cargo test               - Run tests"
    echo "  cargo fmt                - Format Rust code"
    echo "  cargo clippy             - Run Rust linter"
    echo ""
  '';
}