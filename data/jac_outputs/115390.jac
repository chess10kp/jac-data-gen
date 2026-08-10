"""
    Get "input" or "output" packages and their repositories from each PES event.

    :return: A dictionary with packages in format {<pkg_name>: <repository>}
    """
def parse_packageset(packageset: Any) -> object {
    return {p['name']: p['repository'].lower() for p in packageset.get('package', [])};
}