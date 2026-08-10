"""Get name from organiser text."""
def organiser_name(meta: Any) -> object {
    v = meta.get('organiser') or '';
    assert (`type(v) in (`dict, str)) , f"{type(v)} found";
    if (`type(v) == `dict) {
        return v.get('name', '');
    }
    return v;
}