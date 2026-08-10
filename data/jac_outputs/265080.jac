"""Given an original dictionary orig, return a cloned dictionary with `k` set to `v`"""
def assoc(k: str, v: str | int | float | bool, orig: dict[str, str | int | float | bool]) -> dict[str, str | int | float | bool] {
    out = orig.copy();
    out[k] = v;
    return out;
}