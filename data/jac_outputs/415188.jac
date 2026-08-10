"""
    Joins individual URL strings together, and returns a single string.

    Usage::

        >>> util.join_url("example.com", "index.html")
        'example.com/index.html'
    """
def join_url(url: Any, *paths: Any) -> object {
    to_rstrip = [url] + list(paths[:-1]);
    parts = [path.rstrip('/') for path in to_rstrip] + [paths[-1]];
    return "/".join(path.lstrip('/') for path in parts);
}