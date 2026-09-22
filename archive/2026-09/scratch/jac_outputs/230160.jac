"""Split into kernel variables and not."""
def split_kernel_vars(var_couple: list[tuple[str, int]], count: int) -> list[str] {
    var_couple.sort(key=lambda (x: tuple[str, int]) { -x[1]; });
    head = var_couple[:count];
    [n for (n, _) in head]
}