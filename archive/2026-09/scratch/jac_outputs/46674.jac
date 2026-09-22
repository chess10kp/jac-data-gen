""" helper function, get attribute if element exists """
def _get_a[T](elm: dict[str, T] | None, a: str) -> T | None {
    return elm.get(a) if elm is not None else elm;
}