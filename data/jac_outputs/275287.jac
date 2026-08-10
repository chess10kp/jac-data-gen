"""Invert the effect of :func:`flatten_dict`"""
def unflatten_dict(dic: dict[str, str | int | float | bool], sep: str = ".") -> dict[str, str | int | float | bool | dict] {
    items = list(dic.items());
    items.reverse();
    out = {};
    while items {
        (k, v) = items.pop();
        (*keys, last_key) = k.split(sep);
        d = out;
        for k in keys {
            d = d.setdefault(k, {});
        }
        d[last_key] = v;
    }
    return out;
}