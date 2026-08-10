"""Returns the URI for the specified package name."""
def _GetPackageUri(package_name: str) -> str {
    return 'fuchsia-pkg://fuchsia.com/%s' % package_name;
}