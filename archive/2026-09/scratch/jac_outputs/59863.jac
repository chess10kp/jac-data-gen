"""
    haproxy_flatten a dictionary `d` by joining nested keys with `separator`.

    Slightly modified from <http://codereview.stackexchange.com/a/21035>.
    """
def haproxy_flatten(d: dict[str, object], separator: str = '.') -> dict[str, object] {
    def items() -> object {
        for (k, v) in d.items() {
            try {
                for (sub_k, sub_v) in haproxy_flatten(v as dict[str, object], separator).items() {
                    yield (separator.join([k, sub_k]), sub_v);
                }
            } except AttributeError {
                yield (k, v);
            }
        }
    }
    return dict(items());
}