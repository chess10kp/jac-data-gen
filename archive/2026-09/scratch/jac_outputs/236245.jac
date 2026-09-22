"""Returns True if this value should not be inspected due to potential bugs."""
def do_not_inspect(v: function) -> bool {
    if type(v).__name__ != "fused_cython_function" {
        return False;
    }
    return bool(getattr(v, "__defaults__", False));
}