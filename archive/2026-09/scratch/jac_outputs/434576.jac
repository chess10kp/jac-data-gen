"""Returns the union of x and y.

  y takes predescence.
  """
def _dict_deep_merge(
    x: dict[str, object] | object | None,
    y: dict[str, object] | object | None
) -> dict[str, object] | object | None {
    if x is None {
        return y;
    }
    if y is None {
        return x;
    }
    if isinstance(x, dict) {
        if isinstance(y, dict) {
            return {k: _dict_deep_merge(x.get(k), y.get(k)) for k in set(x).union(y)};
        }
        assert y is None, repr(y);
        return x;
    }
    if isinstance(y, dict) {
        assert x is None, repr(x);
        return y;
    }
    return y;
}