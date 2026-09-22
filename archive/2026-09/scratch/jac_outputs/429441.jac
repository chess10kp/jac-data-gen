"""remotes the host and path from a URI, returning only the final resource name
    """
def strip_uri_host_and_path(concept_uri: Any) -> object {
    if (concept_uri is None) {
        return None;
    }
    rightmost_slash_position = concept_uri.rfind('/');
    rightmost_colon_position = concept_uri.rfind(':');
    simplified_start = max(
        0, (rightmost_slash_position + 1), (rightmost_colon_position + 1)
    );
    return concept_uri[simplified_start:];
}