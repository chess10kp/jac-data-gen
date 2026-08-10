"""
    Remaps input_val from source domain to target domain.
    No clamping is performed, the result can be outside of the target domain
    if the input is outside of the source domain.
    """
def remap_unbound(
    input_val: Any, in_from: Any, in_to: Any, out_from: Any, out_to: Any
) -> object {
    out_range = out_to - out_from;
    in_range = in_to - in_from;
    in_val = input_val - in_from;
    val = (float(in_val) / in_range) * out_range;
    out_val = out_from + val;
    return out_val;
}