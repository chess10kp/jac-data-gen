"""Construct a Common Platform Enumeration (CPE) for a given software."""
def construct_cpe(vendor: str, product: str, version: str) -> str {
    return 'cpe:/a:' + vendor + ':' + product + ':' + version;
}