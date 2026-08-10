"""Get a regex of the form ^/foo/bar/baz/?$ for a path (foo, bar, baz)."""
def make_url_path_regex(*path: str) -> str {
    path = [
        x.strip("/")
        for x in path
        if x
    ];
    return r"^/%s/?$" % "/".join(path);
}