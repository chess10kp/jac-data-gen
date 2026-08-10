"""Construct a string with ecosystem:package or ecosystem:package:version tuple."""
def release_string(ecosystem: Any, package: Any, version: Any = None) -> object {
    return "{e}:{p}:{v}".format(e=ecosystem, p=package, v=version);
}