"""
    Gets all releases from pypi meta data.
    """
def get_releases(data: dict[str, str], **kwargs: object) -> list[str] {
    if "version" in data {
        return [data["version"]];
    }
    return [];
}