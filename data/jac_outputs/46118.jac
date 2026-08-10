"""A tuple containing x- and y- slice tuples from a string or tuple."""
def tupletupleint(
    items: str | tuple[tuple[int | float | str, int | float | str], tuple[int | float | str, int | float | str]]
) -> tuple[tuple[int, int], tuple[int, int]] {
    if isinstance(items, str) {
        for s in " ()[]" {
            items = items.replace(s, "");
        }
        (x1, x2, y1, y2) = items.split(",");
        out = ((int(float(x1)), int(float(x2))), (int(float(y1)), int(float(y2))));
    } else {
        ((x1, x2), (y1, y2)) = items;
        out = ((int(float(x1)), int(float(x2))), (int(float(y1)), int(float(y2))));
    }
    return out;
}