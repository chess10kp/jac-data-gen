"""Change a list of providers to be returnable from an aspect.

    Args:
      lib_providers: A list of providers, e.g., as returned from forward_deps().

    Returns:
      A list of providers which is valid to return from an aspect.
    """
def fix_aspect_providers(lib_providers: Any) -> object {
    return [
        p
        for p in lib_providers
        if not hasattr(p, "files")
    ];
}