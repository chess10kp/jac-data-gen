"""Concatenate the inputs to a tuple of variable."""
def concat_variable[T](gx: T | tuple[T, ...] | None, g_input: T | tuple[T, ...] | None) -> tuple[T | None, ...] {
    sum_gx = ();
    if isinstance(gx, tuple) {
        sum_gx = gx;
    } elif gx is not None {
        sum_gx = (gx,);
    }
    if isinstance(g_input, tuple) {
        sum_gx += g_input;
    } elif g_input is not None {
        sum_gx += (g_input,);
    }
    if len(sum_gx) == 0 {
        sum_gx = (None,);
    }
    return sum_gx;
}