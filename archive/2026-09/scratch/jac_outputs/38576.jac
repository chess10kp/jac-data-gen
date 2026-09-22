"""Validate a package name for argparse."""
def package_name(s: str) -> str {
    if s[0] == '-' {
        raise ValueError;
    }
    return s;
}