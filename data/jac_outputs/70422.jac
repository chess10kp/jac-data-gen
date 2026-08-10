"""
    Make given "basePath" a canonical base URL which can be prepended to paths starting with "/".
    """
def canonical_base_url(base_path: str) -> str {
    return base_path.rstrip('/');
}