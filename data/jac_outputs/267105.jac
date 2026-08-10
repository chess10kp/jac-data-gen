"""Format lat/lon region specifier as string suitable for file name."""
def formatRegion(r: str | list[int | float] | tuple[int | float, int | float, int | float, int | float]) -> str {
    if isinstance(r, str) {
        return r;
    }
    strs = [str(i).replace('-', 'm') for i in r];
    return 'region-%s-%sby%s-%s' % tuple(strs);
}