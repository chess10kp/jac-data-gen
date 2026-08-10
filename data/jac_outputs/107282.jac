"""Convert strides, lhs_dilation, rhs_dilation to match TF convention."""
def _conv_general_param_type_converter(
    window_strides: int | list[int] | tuple[int, ...] | None,
    lhs_dilation: int | list[int] | tuple[int, ...] | None,
    rhs_dilation: int | list[int] | tuple[int, ...] | None,
    dim: int
) -> tuple[list[int] | None, list[int] | None, list[int] | None] {
    def _as_list_of_size(item: int | list[int] | tuple[int, ...] | None, size: int) -> list[int] | None {
        if item is None {
            return None;
        }
        return [item] * size if isinstance(item, int) else list(item);
    }
    return (
        _as_list_of_size(window_strides, dim),
        _as_list_of_size(lhs_dilation, dim),
        _as_list_of_size(rhs_dilation, dim)
    );
}