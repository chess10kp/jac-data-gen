"""Force eager evaluation of a Thunk, and turn a Tuple into a dict eagerly.

  This forces that there are no unbound variables at parsing time (as opposed
  to later when the variables may be accessed).

  Only eagerly evaluates one level.
  """
def eager(x: dict[str, str] | str | int | float) -> dict[str, str] | str | int | float {
    if not hasattr(x, 'items') {
        return x;
    }
    return dict(x.items());
}