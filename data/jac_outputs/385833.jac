""" if keys from dict occur in kw, pop them """
def _kw_extract(kw: Any, `dict: Any) -> object {
    for (key, value) in `dict.items() {
        `dict[key] = kw.pop(key, value);
    }
    return (kw, `dict);
}