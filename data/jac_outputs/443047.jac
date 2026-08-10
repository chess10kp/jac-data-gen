glob LICENSE_MAX_LEN = 21;

"""Format license using a short name."""
def format_license(license: str) -> str {
    if len(license) > LICENSE_MAX_LEN {
        license = license[:LICENSE_MAX_LEN - 3] + '...';
    }
    return license;
}