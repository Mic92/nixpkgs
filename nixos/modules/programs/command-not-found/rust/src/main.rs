use std::env;
use std::process::exit;
use rusqlite::{params, Connection, Result};

mod config;

fn query_packages(system: &str, program: &str) -> Result<Vec<String>> {
    let conn = Connection::open(config::DB_PATH)?;
    let mut stmt = conn.prepare("select package from Programs where system = ? and name = ?;")?;
    let iter = stmt.query_map(params![system, program], |row| { row.get(0) })?;
    let mut pkgs: Vec<String> = vec![];
    for pkg in iter {
        pkgs.push(pkg?);
    }
    Ok(pkgs)
}

fn main() {
    let args: Vec<_> = env::args().collect();
    if args.len() < 2 {
        eprintln!("USAGE: {} PROGRAM", args[0]);
        exit(1);
    }
    let program = &args[1];
    let system = env::var("NIX_SYSTEM").unwrap_or(config::NIX_SYSTEM.to_string());
    let packages = match query_packages(&system, program) {
        Ok(packages) => packages,
        Err(err) => {
            eprintln!("Failed to query package database: {}", err);
            exit(1);
        }
    };
    if packages.len() > 0 {
        let advice = if packages.len() > 1 {
            "It is provided by several packages. You can install it by typing on of the of following commands:"
        } else {
            "You can install it by typing:"
        };
        eprintln!("The program '{}' is currently not installed. {}", program, advice);
        for pkg in packages {
            eprintln!("  nix-env -iA nixos.{}", pkg);
        }
    } else {
        eprintln!("{}: command not found", program);
    }
    exit(127);
}
