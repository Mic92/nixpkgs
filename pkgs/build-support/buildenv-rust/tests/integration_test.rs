use std::collections::HashMap;
use std::env;
use std::fs::{self, DirBuilder};
use std::os::unix::fs::{symlink, DirBuilderExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicU32, Ordering};
use std::thread;
use tinyjson::JsonValue;

// Global counter for unique test directory names
static TEST_COUNTER: AtomicU32 = AtomicU32::new(0);

/// Create a unique temporary directory with restricted permissions
fn create_temp_dir(prefix: &str) -> PathBuf {
    // Create a unique directory name using thread ID and atomic counter
    let tid = thread::current().id();

    // Create a DirBuilder with restricted permissions (0700)
    let mut dir_builder = DirBuilder::new();
    dir_builder.mode(0o700);

    // Try to create test directory atomically with correct permissions
    let mut attempts = 0;
    loop {
        let counter = TEST_COUNTER.fetch_add(1, Ordering::SeqCst);
        let dir_name = format!("{}-{:?}-{}", prefix, tid, counter);
        let temp_dir = env::temp_dir().join(&dir_name);

        // Try to create directory atomically with permissions - create fails if it exists
        match dir_builder.create(&temp_dir) {
            Ok(_) => return temp_dir,
            Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => {
                attempts += 1;
                if attempts >= 100 {
                    panic!("Failed to create unique temporary directory after 100 attempts");
                }
                continue;
            }
            Err(e) => panic!("Failed to create temporary directory: {}", e),
        }
    }
}

/// Test helper to create a temporary directory for tests
struct TestEnv {
    temp_dir: PathBuf,
    store_dir: PathBuf,
    out_dir: PathBuf,
}

impl TestEnv {
    fn new(test_name: &str) -> Self {
        let temp_dir = create_temp_dir(&format!("buildenv-test-{}", test_name));

        let store_dir = temp_dir.join("store");
        fs::create_dir_all(&store_dir).unwrap();

        let out_dir = temp_dir.join("out");

        Self {
            temp_dir,
            store_dir,
            out_dir,
        }
    }

    /// Create a test package in the store
    fn create_package(&self, name: &str) -> PathBuf {
        let pkg_dir = self.store_dir.join(name);
        fs::create_dir_all(&pkg_dir).unwrap();
        pkg_dir
    }

    /// Add a file to a package
    fn add_file(&self, pkg_dir: &Path, rel_path: &str, content: &str) {
        let file_path = pkg_dir.join(rel_path);
        if let Some(parent) = file_path.parent() {
            fs::create_dir_all(parent).unwrap();
        }
        fs::write(&file_path, content).unwrap();
    }

    /// Add a directory to a package
    fn add_dir(&self, pkg_dir: &Path, rel_path: &str) {
        let dir_path = pkg_dir.join(rel_path);
        fs::create_dir_all(&dir_path).unwrap();
    }

    /// Add a symlink to a package
    fn add_symlink(&self, pkg_dir: &Path, rel_path: &str, target: &str) {
        let link_path = pkg_dir.join(rel_path);
        if let Some(parent) = link_path.parent() {
            fs::create_dir_all(parent).unwrap();
        }
        symlink(target, &link_path).unwrap();
    }

    /// Add a file with specific permissions
    fn add_file_with_perms(&self, pkg_dir: &Path, rel_path: &str, content: &str, mode: u32) {
        self.add_file(pkg_dir, rel_path, content);
        let file_path = pkg_dir.join(rel_path);
        let mut perms = fs::metadata(&file_path).unwrap().permissions();
        perms.set_mode(mode);
        fs::set_permissions(&file_path, perms).unwrap();
    }

    /// Create propagated packages file
    fn add_propagated(&self, pkg_dir: &Path, deps: &[&str]) {
        let content = deps.join(" ");
        self.add_file(pkg_dir, "nix-support/propagated-user-env-packages", &content);
    }

    /// Run buildenv with given environment variables
    fn run_buildenv(&self, env_vars: Vec<(&str, &str)>) -> Result<(), String> {
        let mut cmd = Command::new(env!("CARGO_BIN_EXE_nix-buildenv"));

        // Set required environment variables
        cmd.env("out", &self.out_dir);
        cmd.env("storeDir", &self.store_dir);

        // Set provided environment variables
        for (key, value) in env_vars {
            cmd.env(key, value);
        }

        let output = cmd.output().expect("Failed to execute buildenv");

        if output.status.success() {
            Ok(())
        } else {
            Err(String::from_utf8_lossy(&output.stderr).to_string())
        }
    }

    /// Check if a symlink exists and points to the expected target
    fn check_symlink(&self, rel_path: &str, expected_target: &str) -> bool {
        let link_path = self.out_dir.join(rel_path.trim_start_matches('/'));
        if let Ok(target) = fs::read_link(&link_path) {
            target.to_string_lossy() == expected_target
        } else {
            false
        }
    }

    /// Check if a directory exists
    fn check_dir(&self, rel_path: &str) -> bool {
        let dir_path = self.out_dir.join(rel_path.trim_start_matches('/'));
        dir_path.is_dir()
    }

    /// Check if a path exists
    fn check_exists(&self, rel_path: &str) -> bool {
        let path = self.out_dir.join(rel_path.trim_start_matches('/'));
        path.exists()
    }

    /// Create packages JSON using tinyjson
    fn create_packages_json(&self, packages: &[(&Path, i32)]) -> String {
        let mut json_packages = Vec::new();

        for (path, priority) in packages {
            let mut pkg_obj = HashMap::new();

            // Create paths array
            let paths = vec![JsonValue::String(path.to_string_lossy().to_string())];
            pkg_obj.insert("paths".to_string(), JsonValue::Array(paths));

            // Add priority
            pkg_obj.insert("priority".to_string(), JsonValue::Number(*priority as f64));

            json_packages.push(JsonValue::Object(pkg_obj));
        }

        JsonValue::Array(json_packages).stringify().unwrap()
    }
}

impl Drop for TestEnv {
    fn drop(&mut self) {
        // Clean up temporary directory
        let _ = fs::remove_dir_all(&self.temp_dir);
    }
}

#[test]
fn test_basic_single_package() {
    let env = TestEnv::new("basic-single");

    // Create a simple package
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/hello", "#!/bin/sh\necho hello");
    env.add_file(&pkg1, "share/doc/hello.txt", "Hello documentation");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check results
    assert!(env.check_symlink("/bin/hello", &pkg1.join("bin/hello").to_string_lossy()));
    assert!(env.check_symlink("/share/doc/hello.txt", &pkg1.join("share/doc/hello.txt").to_string_lossy()));
}

#[test]
fn test_multiple_packages_no_collision() {
    let env = TestEnv::new("multiple-no-collision");

    // Create two packages with different files
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/app1", "#!/bin/sh\necho app1");
    env.add_file(&pkg1, "share/doc/app1.txt", "App1 documentation");

    let pkg2 = env.create_package("pkg2");
    env.add_file(&pkg2, "bin/app2", "#!/bin/sh\necho app2");
    env.add_file(&pkg2, "share/doc/app2.txt", "App2 documentation");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check results - both packages' files should be linked
    assert!(env.check_symlink("/bin/app1", &pkg1.join("bin/app1").to_string_lossy()));
    assert!(env.check_symlink("/bin/app2", &pkg2.join("bin/app2").to_string_lossy()));
    assert!(env.check_dir("/share/doc"));
}

#[test]
fn test_collision_with_same_content() {
    let env = TestEnv::new("collision-same-content");

    // Create two packages with the same file content
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/common", "#!/bin/sh\necho common");

    let pkg2 = env.create_package("pkg2");
    env.add_file(&pkg2, "bin/common", "#!/bin/sh\necho common");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv with checkCollisionContents enabled (default)
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("checkCollisionContents", "1"),
    ]);

    // Should succeed because content is the same
    assert!(result.is_ok(), "buildenv failed: {:?}", result);
    assert!(env.check_exists("/bin/common"));
}

#[test]
fn test_collision_with_different_content() {
    let env = TestEnv::new("collision-different-content");

    // Create two packages with different file content
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/conflict", "#!/bin/sh\necho version1");

    let pkg2 = env.create_package("pkg2");
    env.add_file(&pkg2, "bin/conflict", "#!/bin/sh\necho version2");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv without ignoreCollisions
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("ignoreCollisions", "0"),
    ]);

    // Should fail due to collision
    assert!(result.is_err(), "buildenv should have failed due to collision");
    assert!(result.unwrap_err().contains("collision"));
}

#[test]
fn test_collision_with_ignore() {
    let env = TestEnv::new("collision-with-ignore");

    // Create two packages with different file content
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/conflict", "#!/bin/sh\necho version1");

    let pkg2 = env.create_package("pkg2");
    env.add_file(&pkg2, "bin/conflict", "#!/bin/sh\necho version2");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv with ignoreCollisions
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("ignoreCollisions", "1"),
    ]);

    // Should succeed, using the first package's file
    assert!(result.is_ok(), "buildenv failed: {:?}", result);
    assert!(env.check_symlink("/bin/conflict", &pkg1.join("bin/conflict").to_string_lossy()));
}

#[test]
fn test_priority_handling() {
    let env = TestEnv::new("priority");

    // Create two packages with the same file but different priorities
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/app", "#!/bin/sh\necho low-priority");

    let pkg2 = env.create_package("pkg2");
    env.add_file(&pkg2, "bin/app", "#!/bin/sh\necho high-priority");

    // Create packages JSON - pkg2 has higher priority (lower number)
    let pkgs_json = env.create_packages_json(&[(&pkg1, 10), (&pkg2, 5)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("ignoreCollisions", "1"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Should link to pkg2 (higher priority)
    assert!(env.check_symlink("/bin/app", &pkg2.join("bin/app").to_string_lossy()));
}

#[test]
fn test_paths_to_link_filtering() {
    let env = TestEnv::new("paths-to-link");

    // Create a package with multiple directories
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/app", "#!/bin/sh\necho app");
    env.add_file(&pkg1, "share/doc/readme.txt", "Documentation");
    env.add_file(&pkg1, "lib/libfoo.so", "library");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv with limited pathsToLink
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/bin /share"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that only specified paths are linked
    assert!(env.check_symlink("/bin/app", &pkg1.join("bin/app").to_string_lossy()));
    assert!(env.check_exists("/share/doc/readme.txt"));
    assert!(!env.check_exists("/lib/libfoo.so")); // Should not be linked
}

#[test]
fn test_propagated_packages() {
    let env = TestEnv::new("propagated");

    // Create dependency package
    let dep = env.create_package("dep");
    env.add_file(&dep, "lib/libdep.so", "dependency library");

    // Create main package with propagated dependency
    let pkg = env.create_package("pkg");
    env.add_file(&pkg, "bin/app", "#!/bin/sh\necho app");
    env.add_propagated(&pkg, &[&dep.to_string_lossy()]);

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that both package and dependency are linked
    assert!(env.check_symlink("/bin/app", &pkg.join("bin/app").to_string_lossy()));
    assert!(env.check_symlink("/lib/libdep.so", &dep.join("lib/libdep.so").to_string_lossy()));
}

#[test]
fn test_extra_prefix() {
    let env = TestEnv::new("extra-prefix");

    // Create a package
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/app", "#!/bin/sh\necho app");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv with extraPrefix
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("extraPrefix", "/usr/local"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that files are linked under the prefix
    let link_path = env.out_dir.join("usr/local/bin/app");
    assert!(link_path.exists());
    assert!(link_path.is_symlink());
}

#[test]
fn test_manifest_creation() {
    let env = TestEnv::new("manifest");

    // Create a package
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/app", "#!/bin/sh\necho app");

    // Create a manifest file
    let manifest_file = env.temp_dir.join("manifest.nix");
    fs::write(&manifest_file, "{ test = true; }").unwrap();

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv with manifest
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("manifest", &manifest_file.to_string_lossy()),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that manifest symlink is created
    let manifest_link = env.out_dir.join("manifest");
    assert!(manifest_link.exists());
    assert!(manifest_link.is_symlink());
    assert_eq!(fs::read_link(&manifest_link).unwrap(), manifest_file);
}

#[test]
fn test_dangling_symlink() {
    let env = TestEnv::new("dangling-symlink");

    // Create a package with a dangling symlink
    let pkg1 = env.create_package("pkg1");
    env.add_symlink(&pkg1, "bin/broken", "/nonexistent/target");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    // Should succeed with warning
    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Symlink should be created even though it's dangling
    let link_path = env.out_dir.join("bin/broken");
    assert!(link_path.is_symlink());
}

#[test]
fn test_directory_merging() {
    let env = TestEnv::new("directory-merging");

    // Create two packages with files in the same directory
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "share/icons/app1.png", "icon1");
    env.add_file(&pkg1, "share/doc/app1.txt", "doc1");

    let pkg2 = env.create_package("pkg2");
    env.add_file(&pkg2, "share/icons/app2.png", "icon2");
    env.add_file(&pkg2, "share/man/app2.1", "man2");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that directories are properly merged
    assert!(env.check_dir("/share"));
    assert!(env.check_dir("/share/icons"));
    assert!(env.check_symlink("/share/icons/app1.png", &pkg1.join("share/icons/app1.png").to_string_lossy()));
    assert!(env.check_symlink("/share/icons/app2.png", &pkg2.join("share/icons/app2.png").to_string_lossy()));
    assert!(env.check_symlink("/share/doc/app1.txt", &pkg1.join("share/doc/app1.txt").to_string_lossy()));
    assert!(env.check_symlink("/share/man/app2.1", &pkg2.join("share/man/app2.1").to_string_lossy()));
}

#[test]
fn test_ignore_single_file_outputs() {
    let env = TestEnv::new("single-file-outputs");

    // Create a store path that is a file (not a directory)
    let file_pkg = env.store_dir.join("single-file");
    fs::write(&file_pkg, "I am a file package").unwrap();

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&file_pkg, 0)]);

    // Test with ignoreSingleFileOutputs = false (default)
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("ignoreSingleFileOutputs", "0"),
    ]);

    // Should fail
    assert!(result.is_err(), "buildenv should have failed for single file");
    assert!(result.unwrap_err().contains("is a file and can't be merged"));

    // Test with ignoreSingleFileOutputs = true
    let env2 = TestEnv::new("single-file-outputs-ignore");
    let file_pkg2 = env2.store_dir.join("single-file");
    fs::write(&file_pkg2, "I am a file package").unwrap();

    let pkgs_json2 = env2.create_packages_json(&[(&file_pkg2, 0)]);

    let result2 = env2.run_buildenv(vec![
        ("pkgs", &pkgs_json2),
        ("pathsToLink", "/"),
        ("ignoreSingleFileOutputs", "1"),
    ]);

    // Should succeed with warning
    assert!(result2.is_ok(), "buildenv failed: {:?}", result2);
}

#[test]
fn test_permission_preservation() {
    let env = TestEnv::new("permissions");

    // Create a package with specific permissions
    let pkg1 = env.create_package("pkg1");
    env.add_file_with_perms(&pkg1, "bin/executable", "#!/bin/sh\necho exec", 0o755);
    env.add_file_with_perms(&pkg1, "etc/config", "configuration", 0o644);

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that symlinks are created (permissions of symlinks don't matter,
    // the target's permissions are what count)
    assert!(env.check_symlink("/bin/executable", &pkg1.join("bin/executable").to_string_lossy()));
    assert!(env.check_symlink("/etc/config", &pkg1.join("etc/config").to_string_lossy()));
}

#[test]
fn test_extra_paths_from_file() {
    let env = TestEnv::new("extra-paths");

    // Create main package
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/main", "#!/bin/sh\necho main");

    // Create extra packages
    let extra1 = env.create_package("extra1");
    env.add_file(&extra1, "lib/libextra1.so", "extra library 1");

    let extra2 = env.create_package("extra2");
    env.add_file(&extra2, "lib/libextra2.so", "extra library 2");

    // Create extra paths file
    let extra_paths_file = env.temp_dir.join("extra-paths");
    let extra_paths_content = vec![extra1.to_string_lossy(), extra2.to_string_lossy()].join("\n") + "\n";
    fs::write(&extra_paths_file, extra_paths_content).unwrap();

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("extraPathsFrom", &extra_paths_file.to_string_lossy()),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that all packages are linked
    assert!(env.check_symlink("/bin/main", &pkg1.join("bin/main").to_string_lossy()));
    assert!(env.check_symlink("/lib/libextra1.so", &extra1.join("lib/libextra1.so").to_string_lossy()));
    assert!(env.check_symlink("/lib/libextra2.so", &extra2.join("lib/libextra2.so").to_string_lossy()));
}

#[test]
fn test_skipped_paths() {
    let env = TestEnv::new("skipped-paths");

    // Create a package with paths that should be skipped
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "bin/app", "#!/bin/sh\necho app");
    env.add_file(&pkg1, "nix-support/setup-hook", "# setup hook");
    env.add_file(&pkg1, "propagated-build-inputs", "deps");
    env.add_file(&pkg1, "share/info/dir", "info directory");
    env.add_file(&pkg1, "share/mime/globs", "mime globs");
    env.add_file(&pkg1, "share/mime/packages/app.xml", "mime package");
    env.add_file(&pkg1, "lib/perl5/perllocal.pod", "perl local");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that normal files are linked
    assert!(env.check_symlink("/bin/app", &pkg1.join("bin/app").to_string_lossy()));
    assert!(env.check_symlink("/share/mime/packages/app.xml", &pkg1.join("share/mime/packages/app.xml").to_string_lossy()));

    // Check that skipped paths are not linked
    assert!(!env.check_exists("/nix-support"));
    assert!(!env.check_exists("/propagated-build-inputs"));
    assert!(!env.check_exists("/share/info/dir"));
    assert!(!env.check_exists("/share/mime/globs"));
    assert!(!env.check_exists("/lib/perl5/perllocal.pod"));
}

#[test]
fn test_empty_package_list() {
    let env = TestEnv::new("empty-packages");

    // Try to run buildenv without packages
    let result = env.run_buildenv(vec![
        ("pathsToLink", "/"),
    ]);

    // Should fail due to missing packages
    assert!(result.is_err(), "buildenv should have failed without packages");
    assert!(result.unwrap_err().contains("No packages specified"));
}

#[test]
fn test_collision_different_permissions() {
    let env = TestEnv::new("collision-permissions");

    // Create two packages with same file but different permissions
    let pkg1 = env.create_package("pkg1");
    env.add_file_with_perms(&pkg1, "bin/app", "#!/bin/sh\necho app", 0o755);

    let pkg2 = env.create_package("pkg2");
    env.add_file_with_perms(&pkg2, "bin/app", "#!/bin/sh\necho app", 0o644);

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
        ("checkCollisionContents", "1"),
    ]);

    // Should fail because files have different permissions
    assert!(result.is_err(), "buildenv should have failed due to different permissions");
    assert!(result.unwrap_err().contains("collision"));
}

#[test]
fn test_symlink_to_symlink() {
    let env = TestEnv::new("symlink-chain");

    // Create a package with a chain of symlinks
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "lib/libfoo.so.1.0", "library content");
    env.add_symlink(&pkg1, "lib/libfoo.so.1", "libfoo.so.1.0");
    env.add_symlink(&pkg1, "lib/libfoo.so", "libfoo.so.1");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that all symlinks are created
    assert!(env.check_symlink("/lib/libfoo.so.1.0", &pkg1.join("lib/libfoo.so.1.0").to_string_lossy()));
    assert!(env.check_symlink("/lib/libfoo.so.1", &pkg1.join("lib/libfoo.so.1").to_string_lossy()));
    assert!(env.check_symlink("/lib/libfoo.so", &pkg1.join("lib/libfoo.so").to_string_lossy()));
}

#[test]
fn test_nested_paths_to_link() {
    let env = TestEnv::new("nested-paths");

    // Create a package with nested structure
    let pkg1 = env.create_package("pkg1");
    env.add_file(&pkg1, "share/doc/app/README", "readme");
    env.add_file(&pkg1, "share/doc/app/LICENSE", "license");
    env.add_file(&pkg1, "share/man/man1/app.1", "manpage");
    env.add_file(&pkg1, "etc/app/config", "config");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0)]);

    // Run buildenv with specific nested path
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/share/doc"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that only the specified path is linked
    assert!(env.check_dir("/share"));
    assert!(env.check_dir("/share/doc"));
    assert!(env.check_exists("/share/doc/app/README"));
    assert!(env.check_exists("/share/doc/app/LICENSE"));
    assert!(!env.check_exists("/share/man")); // Should not be linked
    assert!(!env.check_exists("/etc")); // Should not be linked
}

#[test]
fn test_empty_directories() {
    let env = TestEnv::new("empty-dirs");

    // Create packages with empty directories
    let pkg1 = env.create_package("pkg1");
    env.add_dir(&pkg1, "share/empty");
    env.add_dir(&pkg1, "share/icons/hicolor/48x48/apps");
    env.add_file(&pkg1, "share/icons/hicolor/48x48/apps/app1.png", "icon1");

    let pkg2 = env.create_package("pkg2");
    env.add_dir(&pkg2, "share/empty");  // Same empty dir in both packages
    env.add_dir(&pkg2, "share/icons/hicolor/32x32/apps");
    env.add_file(&pkg2, "share/icons/hicolor/32x32/apps/app2.png", "icon2");

    // Create packages JSON
    let pkgs_json = env.create_packages_json(&[(&pkg1, 0), (&pkg2, 0)]);

    // Run buildenv
    let result = env.run_buildenv(vec![
        ("pkgs", &pkgs_json),
        ("pathsToLink", "/"),
    ]);

    assert!(result.is_ok(), "buildenv failed: {:?}", result);

    // Check that directories are properly created and merged
    assert!(env.check_dir("/share/empty"));
    assert!(env.check_dir("/share/icons/hicolor/48x48/apps"));
    assert!(env.check_dir("/share/icons/hicolor/32x32/apps"));
    assert!(env.check_exists("/share/icons/hicolor/48x48/apps/app1.png"));
    assert!(env.check_exists("/share/icons/hicolor/32x32/apps/app2.png"));
}
