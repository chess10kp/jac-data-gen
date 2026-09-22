"""get sub dictionary recursive."""
def _get_sub_dict(d: dict[str, dict], *names: str) -> dict {
    for name in names {
        nxt = d.get(name, None);
        if nxt is None {
            return dict();
        }
        d = nxt;
    }
    return d;
}