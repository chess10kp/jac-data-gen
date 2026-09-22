def _rewrite_machine_info(
    current_machine_info_contents: str, new_pretty_hostname: str
) -> str:
    """
    Return current_machine_info_contents - the full contents of
    /etc/machine-info - with the PRETTY_HOSTNAME=... line rewritten to refer
    to new_pretty_hostname.
    """
    current_lines = current_machine_info_contents.splitlines()
    preserved_lines = [
        ln for ln in current_lines if not ln.startswith("PRETTY_HOSTNAME")
    ]
    new_lines = preserved_lines + [f"PRETTY_HOSTNAME={new_pretty_hostname}"]
    new_contents = "\n".join(new_lines) + "\n"
    return new_contents

assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=foo\nPRETTY_HOSTNAME=bar\n", "bar"
) == "PRETTY_HOSTNAME=bar\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=myhost", "myhost"
) == "PRETTY_HOSTNAME=myhost\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=test-host-1\n"
    "PRETTY_HOSTNAME=test-host-2\n"
    "PRETTY_HOSTNAME=test-host-3\n",
    "new-test-host-1",
) == "PRETTY_HOSTNAME=new-test-host-1\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=foo\nPRETTY_HOSTNAME=bar", "bar"
) == "PRETTY_HOSTNAME=bar\n"
assert _rewrite_machine_info("hello\n", "new_value") == "hello\nPRETTY_HOSTNAME=new_value\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=test-host-1\n"
    "PRETTY_HOSTNAME=test-host-2\n"
    "PRETTY_HOSTNAME=test-host-3\n"
    "PRETTY_HOSTNAME=test-host-4\n",
    "new-test-host-1",
) == "PRETTY_HOSTNAME=new-test-host-1\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=abc\nPRETTY_HOSTNAME=def\nPRETTY_HOSTNAME=ghi\n",
    "jkl",
) == "PRETTY_HOSTNAME=jkl\n"
assert _rewrite_machine_info(
    """
PRETTY_HOSTNAME=
""",
    "myhost",
) == """
PRETTY_HOSTNAME=myhost
"""
assert _rewrite_machine_info(
    """\
# Comments are ignored
PRETTY_HOSTNAME=foo
""",
    "bar",
) == """\
# Comments are ignored
PRETTY_HOSTNAME=bar
"""
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=old_value\n", "new_value"
) == "PRETTY_HOSTNAME=new_value\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=test-host-1\n"
    "PRETTY_HOSTNAME=test-host-2\n",
    "new-test-host-1",
) == "PRETTY_HOSTNAME=new-test-host-1\n"
assert _rewrite_machine_info(
    "PRETTY_HOSTNAME=foo", "bar"
) == "PRETTY_HOSTNAME=bar\n"
assert _rewrite_machine_info(
    """
PRETTY_HOSTNAME=foo
""",
    "myhost",
) == """
PRETTY_HOSTNAME=myhost
"""
assert _rewrite_machine_info(
    """
PRETTY_HOSTNAME=
""",
    "some-new-pretty-hostname",
) == """
PRETTY_HOSTNAME=some-new-pretty-hostname
"""
assert _rewrite_machine_info(
    """
PRETTY_HOSTNAME=some-pretty-hostname
""",
    "some-new-pretty-hostname",
) == """
PRETTY_HOSTNAME=some-new-pretty-hostname
"""
assert _rewrite_machine_info(
    """
# Comments are preserved
PRETTY_HOSTNAME=old_value
""",
    "new_value",
) == """
# Comments are preserved
PRETTY_HOSTNAME=new_value
"""
