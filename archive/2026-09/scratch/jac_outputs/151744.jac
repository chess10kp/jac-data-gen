"""Use this to get page orientation right."""
def landscape(pagesize: tuple[int, int]) -> tuple[int, int] {
    (a, b) = pagesize;
    return (b, a) if a < b else (a, b);
}