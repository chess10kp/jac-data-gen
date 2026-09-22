"""
    Extract all (and only) the path vars in a dictionary.

    :param d: a .paths.json data structure
    :return: all path var definitions without any special entries like '__ENV'
    """
def path_vars_in(d: dict[str, object]) -> list[tuple[str, object]] {
    return [p for p in d.items() if p[0] != '__ENV'];
}