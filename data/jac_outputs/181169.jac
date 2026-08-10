"""Returns a tuple to be hashed, convert function into their name."""
def pack_params(params: list) -> tuple {
    lp = [];
    for x in params {
        if callable(x) {
            lp.append(x.__name__);
        } else {
            lp.append(x);
        }
    }
    return tuple(lp);
}