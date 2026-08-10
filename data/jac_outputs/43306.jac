"""Combine an iterable of dictionaries with nested merge semantics."""
def nested_combine(*dicts: dict) -> dict {
    r: dict = {};
    for d in dicts {
        for k in d {
            if k in r and isinstance(r[k], dict) {
                if isinstance(d[k], dict) {
                    r[k] = nested_combine(r[k], d[k]);
                } else {
                    raise ValueError(
                        "Key {!r} is a dict in one config but not another! PANIC: "
                        "{!r}".format(
                            k, d[k]
                        )
                    );
                }
            } else {
                r[k] = d[k];
            }
        }
    }
    return r;
}