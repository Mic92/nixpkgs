use std::collections::HashMap;
use std::env;
use std::fmt;
use std::fs;
use std::io;
use std::os::unix::fs::{symlink, PermissionsExt};
use std::path::{Path, PathBuf};
use tinyjson::JsonValue;

#[derive(Debug)]
enum Error {
    Io { path: PathBuf, source: io::Error, context: String },
    Env { var: String },
    Json { message: String },
    Collision { old: String, new: String },
    StorePath { path: PathBuf },
    NotADirectory { path: PathBuf },
    MissingPackages,
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Io { path, source, context } => {
                write!(f, "{} ({}): {}", context, path.display(), source)
            }
            Error::Env { var } => write!(f, "Missing required environment variable '{}'", var),
            Error::Json { message } => write!(f, "JSON error: {}", message),
            Error::Collision { old, new } => write!(f, "collision between {} and {}", old, new),
            Error::StorePath { path } => write!(
                f,
                "The store path {} is a file and can't be merged into an environment using pkgs.buildEnv!",
                path.display()
            ),
            Error::NotADirectory { path } => write!(f, "not a directory: `{}''", path.display()),
            Error::MissingPackages => write!(
                f,
                "No packages specified: neither 'pkgs' nor 'pkgsPath' environment variable is set"
            ),
        }
    }
}

impl std::error::Error for Error {}

type Result<T> = std::result::Result<T, Error>;

// Helper trait for adding context to io::Error
trait IoResultExt<T> {
    fn context(self, context: &str, path: &Path) -> Result<T>;
}

impl<T> IoResultExt<T> for io::Result<T> {
    fn context(self, context: &str, path: &Path) -> Result<T> {
        self.map_err(|e| Error::Io {
            path: path.to_path_buf(),
            source: e,
            context: context.to_string(),
        })
    }
}

// Helper trait for adding context to JSON operations
trait JsonResultExt<T> {
    fn json_context(self, context: &str) -> Result<T>;
}

impl<T> JsonResultExt<T> for Option<T> {
    fn json_context(self, context: &str) -> Result<T> {
        self.ok_or_else(|| Error::Json {
            message: context.to_string(),
        })
    }
}

impl<T, E: fmt::Display> JsonResultExt<T> for std::result::Result<T, E> {
    fn json_context(self, context: &str) -> Result<T> {
        self.map_err(|e| Error::Json {
            message: format!("{}: {}", context, e),
        })
    }
}

#[derive(Debug)]
struct Config {
    out: PathBuf,
    extra_prefix: String,
    paths_to_link: Vec<String>,
    ignore_collisions: bool,
    check_collision_contents: bool,
    ignore_single_file_outputs: bool,
    pkgs: Option<String>,
    pkgs_path: Option<String>,
    extra_paths_from: Option<String>,
    manifest: String,
    store_dir: String,
}

impl Config {
    fn from_env() -> Result<Self> {
        let out = env::var("out").map_err(|_| Error::Env {
            var: "out".to_string(),
        })?;
        let out = PathBuf::from(out);

        let extra_prefix = env::var("extraPrefix").unwrap_or_default();

        let paths_to_link = env::var("pathsToLink")
            .map_err(|_| Error::Env {
                var: "pathsToLink".to_string(),
            })?
            .split_whitespace()
            .map(|s| s.to_string())
            .collect();

        let ignore_collisions =
            env::var("ignoreCollisions").unwrap_or_else(|_| "0".to_string()) == "1";

        let check_collision_contents =
            env::var("checkCollisionContents").unwrap_or_else(|_| "1".to_string()) == "1";

        let ignore_single_file_outputs =
            env::var("ignoreSingleFileOutputs").unwrap_or_else(|_| "0".to_string()) == "1";

        let pkgs = env::var("pkgs").ok();
        let pkgs_path = env::var("pkgsPath").ok();
        let extra_paths_from = env::var("extraPathsFrom").ok();
        let manifest = env::var("manifest").unwrap_or_default();
        let store_dir = env::var("storeDir").unwrap_or_else(|_| "/nix/store".to_string());

        Ok(Config {
            out,
            extra_prefix,
            paths_to_link,
            ignore_collisions,
            check_collision_contents,
            ignore_single_file_outputs,
            pkgs,
            pkgs_path,
            extra_paths_from,
            manifest,
            store_dir,
        })
    }
}

#[derive(Debug)]
struct Package {
    paths: Vec<String>,
    priority: i32,
}

#[derive(Debug, Clone)]
struct SymlinkEntry {
    target: String,
    priority: i32,
}

struct BuildEnv {
    config: Config,
    symlinks: HashMap<String, SymlinkEntry>,
    done: HashMap<String, bool>,
    postponed: HashMap<String, bool>,
}

impl BuildEnv {
    fn new(config: Config) -> Self {
        let mut symlinks = HashMap::new();
        // Add all pathsToLink and all parent directories
        symlinks.insert(
            String::new(),
            SymlinkEntry {
                target: String::new(),
                priority: 0,
            },
        );

        for path in &config.paths_to_link {
            let parts: Vec<&str> = path.split('/').filter(|s| !s.is_empty()).collect();
            let mut cur = String::new();
            for part in parts {
                cur.push('/');
                cur.push_str(part);
                symlinks.insert(
                    cur.clone(),
                    SymlinkEntry {
                        target: String::new(),
                        priority: 0,
                    },
                );
            }
        }

        Self {
            config,
            symlinks,
            done: HashMap::new(),
            postponed: HashMap::new(),
        }
    }

    fn is_in_paths_to_link(&self, path: &str) -> bool {
        let path = if path.is_empty() { "/" } else { path };
        for elem in &self.config.paths_to_link {
            if elem == "/" {
                return true;
            }
            if path.starts_with(elem) && (path == elem || path.chars().nth(elem.len()) == Some('/'))
            {
                return true;
            }
        }
        false
    }

    fn has_paths_to_link(&self, path: &str) -> bool {
        for elem in &self.config.paths_to_link {
            if path.is_empty() {
                return true;
            }
            if elem.starts_with(path) && (path == elem || elem.chars().nth(path.len()) == Some('/'))
            {
                return true;
            }
        }
        false
    }

    fn is_store_path(&self, path: &Path) -> bool {
        if let Some(parent) = path.parent() {
            return path.is_absolute() && parent == Path::new(&self.config.store_dir);
        }
        false
    }

    fn check_collision(&self, path1: &Path, path2: &Path) -> Result<bool> {
        if !path1.exists() || !path2.exists() {
            return Ok(false);
        }

        let meta1 = fs::metadata(path1).context("Failed to get metadata", path1)?;
        let meta2 = fs::metadata(path2).context("Failed to get metadata", path2)?;

        let mode1 = meta1.permissions().mode() & 0o7777;
        let mode2 = meta2.permissions().mode() & 0o7777;

        if mode1 != mode2 {
            eprintln!(
                "warning: different permissions in `{}' and `{}': {:04o} <-> {:04o}",
                path1.display(),
                path2.display(),
                mode1,
                mode2
            );
            return Ok(false);
        }

        if meta1.is_file() && meta2.is_file() {
            let content1 = fs::read(path1).context("Failed to read file", path1)?;
            let content2 = fs::read(path2).context("Failed to read file", path2)?;
            Ok(content1 == content2)
        } else {
            Ok(meta1.file_type() == meta2.file_type())
        }
    }

    fn find_files(
        &mut self,
        rel_name: &str,
        target: &Path,
        base_name: &str,
        priority: i32,
    ) -> Result<()> {
        // Check if store path is a file
        if target.is_file() && self.is_store_path(target) {
            if self.config.ignore_single_file_outputs {
                eprintln!(
                    "warning: The store path {} is a file and can't be merged into an environment using pkgs.buildEnv",
                    target.display()
                );
                return Ok(());
            } else {
                return Err(Error::StorePath {
                    path: target.to_path_buf(),
                });
            }
        }

        // Skip certain paths
        if rel_name == "/propagated-build-inputs"
            || rel_name == "/nix-support"
            || rel_name.ends_with("/info/dir")
            || (rel_name.starts_with("/share/mime/")
                && !rel_name.starts_with("/share/mime/packages"))
            || base_name == "perllocal.pod"
            || base_name == "log"
            || !(self.has_paths_to_link(rel_name) || self.is_in_paths_to_link(rel_name))
        {
            return Ok(());
        }

        let old_entry = self.symlinks.get(rel_name).cloned();
        let (old_target, old_priority) = match old_entry {
            Some(entry) => (entry.target, entry.priority),
            None => (String::new(), i32::MAX),
        };

        // If target doesn't exist or has higher priority, create/update it
        if old_target.is_empty()
            || (priority < old_priority
                && (!old_target.is_empty() && !Path::new(&old_target).is_dir()))
        {
            // Check for dangling symlink
            if target.is_symlink() && !target.exists() {
                if let Ok(link) = fs::read_link(target) {
                    eprintln!(
                        "warning: creating dangling symlink `{}{}{}' -> `{}' -> `{}'",
                        self.config.out.display(),
                        self.config.extra_prefix,
                        rel_name,
                        target.display(),
                        link.display()
                    );
                }
            }
            // Only create a symlink if target is not a directory
            if !target.is_dir() {
                self.symlinks.insert(
                    rel_name.to_string(),
                    SymlinkEntry {
                        target: target.to_string_lossy().to_string(),
                        priority,
                    },
                );
                return Ok(());
            }
        }

        // If both targets resolve to the same path, skip
        if !old_target.is_empty() {
            if let (Ok(abs_target), Ok(abs_old_target)) =
                (target.canonicalize(), Path::new(&old_target).canonicalize())
            {
                if abs_target == abs_old_target {
                    // Prefer non-symlink
                    if Path::new(&old_target).is_symlink() && !target.is_symlink() {
                        self.symlinks.insert(
                            rel_name.to_string(),
                            SymlinkEntry {
                                target: target.to_string_lossy().to_string(),
                                priority,
                            },
                        );
                    }
                    return Ok(());
                }
            }
        }

        // Skip if higher priority
        if !old_target.is_empty() && priority > old_priority && !Path::new(&old_target).is_dir() {
            return Ok(());
        }

        // Check if target should be a directory
        if old_target.is_empty() && !target.is_dir() {
            return Err(Error::NotADirectory {
                path: target.to_path_buf(),
            });
        }

        // Handle collisions
        if !target.is_dir() || (!old_target.is_empty() && !Path::new(&old_target).is_dir()) {
            let target_ref = self.prepend_dangling(target);
            let old_target_ref = self.prepend_dangling(Path::new(&old_target));

            if self.config.ignore_collisions {
                eprintln!(
                    "warning: collision between {} and {}",
                    target_ref, old_target_ref
                );
                return Ok(());
            } else if self.config.check_collision_contents
                && self.check_collision(Path::new(&old_target), target)?
            {
                return Ok(());
            } else {
                return Err(Error::Collision {
                    old: old_target_ref,
                    new: target_ref,
                });
            }
        }

        // Recurse into directories
        if !old_target.is_empty() {
            self.find_files_in_dir(
                rel_name,
                Path::new(&old_target),
                old_priority,
            )?;
        }
        self.find_files_in_dir(
            rel_name,
            target,
            priority,
        )?;

        // Mark as directory
        self.symlinks.insert(
            rel_name.to_string(),
            SymlinkEntry {
                target: String::new(),
                priority,
            },
        );

        Ok(())
    }

    fn find_files_in_dir(
        &mut self,
        rel_name: &str,
        target: &Path,
        priority: i32,
    ) -> Result<()> {
        for entry in fs::read_dir(target).context("Failed to read directory", target)?
        {
            let entry = entry.context("Failed to read directory entry", target)?;
            let name = entry.file_name();
            let name_str = name.to_string_lossy();

            if name_str != "." && name_str != ".." {
                let new_rel_name = format!("{}/{}", rel_name, name_str);
                self.find_files(
                    &new_rel_name,
                    &entry.path(),
                    &name_str,
                    priority,
                )?;
            }
        }
        Ok(())
    }

    fn prepend_dangling(&self, path: &Path) -> String {
        if path.is_symlink() && !path.exists() {
            format!("dangling symlink `{}'", path.display())
        } else {
            format!("`{}'", path.display())
        }
    }

    fn add_pkg(
        &mut self,
        pkg_dir: &Path,
        priority: i32,
    ) -> Result<()> {
        let pkg_dir_str = pkg_dir.to_string_lossy().to_string();
        if self.done.contains_key(&pkg_dir_str) {
            return Ok(());
        }
        self.done.insert(pkg_dir_str, true);

        self.find_files(
            "",
            pkg_dir,
            "",
            priority,
        )?;

        // Handle propagated packages
        let propagated_path = pkg_dir.join("nix-support/propagated-user-env-packages");
        if propagated_path.exists() {
            let content = fs::read_to_string(&propagated_path)
                .context("Failed to read propagated packages", &propagated_path)?;
            for p in content.split_whitespace() {
                if !self.done.contains_key(p) {
                    self.postponed.insert(p.to_string(), true);
                }
            }
        }

        Ok(())
    }

    fn parse_packages(&self, json: JsonValue) -> Result<Vec<Package>> {
        let array = json.get::<Vec<_>>()
            .json_context("Expected JSON array of packages")?;

        let mut packages = Vec::new();
        for item in array {
            let obj = item
                .get::<HashMap<String, JsonValue>>()
                .json_context("Expected package object")?;

            let paths_json = obj.get("paths")
                .json_context("Missing 'paths' field")?;
            let paths_array = paths_json.get::<Vec<_>>()
                .json_context("'paths' must be an array")?;

            let mut paths = Vec::new();
            for path_json in paths_array {
                let path = path_json.get::<String>()
                    .json_context("Path must be a string")?;
                paths.push(path.clone());
            }

            let priority = obj
                .get("priority")
                .and_then(|v| v.get::<f64>())
                .map(|f| *f as i32)
                .unwrap_or(0);

            packages.push(Package { paths, priority });
        }

        Ok(packages)
    }

    fn create_symlinks(&self) -> Result<usize> {
        // Ensure the output directory exists
        fs::create_dir_all(&self.config.out)
            .context("Failed to create output directory", &self.config.out)?;

        let mut nr_links = 0;

        for (rel_name, entry) in &self.symlinks {
            if !self.is_in_paths_to_link(rel_name) {
                continue;
            }

            let mut abs_path = self.config.out.clone();
            if !self.config.extra_prefix.is_empty() {
                abs_path = abs_path.join(self.config.extra_prefix.trim_start_matches('/'));
            }
            if !rel_name.is_empty() {
                abs_path = abs_path.join(rel_name.trim_start_matches('/'));
            }

            if entry.target.is_empty() {
                // Create directory
                // Skip if it's the root output directory which already exists
                if abs_path != self.config.out {
                    fs::create_dir_all(&abs_path)
                        .context("Cannot create directory", &abs_path)?;
                }
            } else {
                // Create symlink
                if let Some(parent) = abs_path.parent() {
                    fs::create_dir_all(parent)
                        .context("Failed to create parent directory", parent)?;
                }
                symlink(&entry.target, &abs_path)
                    .context("Error creating symlink", &abs_path)?;
                nr_links += 1;
            }
        }

        Ok(nr_links)
    }

    fn run(&mut self) -> Result<()> {
        // Read packages
        let pkgs_json = if let Some(path) = &self.config.pkgs_path {
            let path_buf = PathBuf::from(path);
            fs::read_to_string(&path_buf)
                .context("Failed to read packages from file", &path_buf)?
        } else if let Some(pkgs) = &self.config.pkgs {
            pkgs.clone()
        } else {
            return Err(Error::MissingPackages);
        };

        let json_value: JsonValue = pkgs_json.parse()
            .json_context("Failed to parse JSON")?;

        let packages = self.parse_packages(json_value)?;

        // Process explicit packages
        for pkg in packages {
            for path in pkg.paths {
                let path_buf = PathBuf::from(&path);
                if path_buf.exists() {
                    self.add_pkg(
                        &path_buf,
                        pkg.priority,
                    )?;
                }
            }
        }

        // Process propagated packages
        let mut priority_counter = 1000;
        while !self.postponed.is_empty() {
            let pkg_dirs: Vec<String> = self.postponed.keys().cloned().collect();
            self.postponed.clear();

            for pkg_dir in pkg_dirs {
                // Temporarily set ignore_collisions to true for propagated packages
                let old_ignore_collisions = self.config.ignore_collisions;
                self.config.ignore_collisions = true;
                self.add_pkg(
                    Path::new(&pkg_dir),
                    priority_counter,
                )?;
                self.config.ignore_collisions = old_ignore_collisions;
                priority_counter += 1;
            }
        }

        // Process extra paths
        if let Some(extra_paths_file) = &self.config.extra_paths_from {
            if !extra_paths_file.is_empty() {
                let path_buf = PathBuf::from(extra_paths_file);
                let content = fs::read_to_string(&path_buf)
                    .context("Failed to read extra paths", &path_buf)?;
                for line in content.lines() {
                    let path = PathBuf::from(line.trim());
                    if path.is_dir() {
                        self.add_pkg(
                            &path,
                            1000,
                        )?;
                    }
                }
            }
        }

        // Create symlinks
        let nr_links = self.create_symlinks()?;
        eprintln!("created {} symlinks in user environment", nr_links);

        // Create manifest symlink if specified
        if !self.config.manifest.is_empty() {
            let manifest_path = self.config.out.join("manifest");
            symlink(&self.config.manifest, &manifest_path)
                .context("Failed to create manifest symlink", &manifest_path)?;
        }

        Ok(())
    }
}

fn main() -> Result<()> {
    if let Err(e) = run() {
        eprintln!("Error: {:#}", e);
        std::process::exit(1);
    }
    Ok(())
}

fn run() -> Result<()> {
    let config = Config::from_env()?;
    let mut build_env = BuildEnv::new(config);
    build_env.run()
}
