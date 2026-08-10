"""
    Returns a name for the resource following the reverse domain name notation
    """
def create_reverse_dns(*resource_name_parts: Any) -> str {
    return ("io.simcore.storage" + ".".join(map(str, resource_name_parts)));
}