expected_lines = {
    "account required @@pam@@/lib/security/pam_unix.so",
    "account sufficient @@pam_krb5@@/lib/security/pam_krb5.so",
    "auth [default=die success=done] @@pam_ccreds@@/lib/security/pam_ccreds.so action=validate use_first_pass",
    "auth [default=ignore success=1 service_err=reset] @@pam_krb5@@/lib/security/pam_krb5.so use_first_pass",
    "auth required @@pam@@/lib/security/pam_deny.so",
    "auth sufficient @@pam_ccreds@@/lib/security/pam_ccreds.so action=store use_first_pass",
    "auth sufficient @@pam@@/lib/security/pam_rootok.so",
    "auth sufficient @@pam@@/lib/security/pam_unix.so likeauth try_first_pass",
    "password sufficient @@pam_krb5@@/lib/security/pam_krb5.so use_first_pass",
    "password sufficient @@pam@@/lib/security/pam_unix.so nullok yescrypt",
    "session optional @@pam_krb5@@/lib/security/pam_krb5.so",
    "session required @@pam@@/lib/security/pam_env.so conffile=/etc/pam/environment readenv=0",
    "session required @@pam@@/lib/security/pam_unix.so",
}
actual_lines = set(machine.succeed("cat /etc/pam.d/chfn").splitlines())

stripped_lines = set([line.split("#")[0].rstrip() for line in actual_lines])
missing_lines = expected_lines - stripped_lines
extra_lines = stripped_lines - expected_lines
non_functional_lines = set([line for line in extra_lines if line == ""])
unexpected_functional_lines = extra_lines - non_functional_lines

with subtest("All expected lines are in the file"):
    assert not missing_lines, f"Missing lines: {missing_lines}"

with subtest("All remaining lines are empty or comments"):
    assert not unexpected_functional_lines, f"Unexpected lines: {unexpected_functional_lines}"
