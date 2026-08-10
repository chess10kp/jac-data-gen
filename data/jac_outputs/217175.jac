"""Return a tuple with *val* inserted into position *idx*."""
def tupleinsert(
    tpl: tuple[int | str | float | bool, ...],
    val: int | str | float | bool,
    idx: int
) -> tuple[int | str | float | bool, ...] {
    lst = list(tpl[:idx]) + [val] + list(tpl[idx:]);
    return tuple(lst);
}