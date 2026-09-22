"""Helper method to process slice keys"""
def _global_to_local_key_slice(
    global_key: slice[int | None],
    globalshape: list[int],
    local_to_global_dict: dict[int, tuple[int, int]] | None,
    axis: int = 0
) -> slice[int | None] {
    if global_key == slice(None) {
        return global_key;
    }
    if local_to_global_dict is None {
        return global_key;
    }
    (global_start, global_stop, global_step) = global_key.indices(globalshape[axis]);
    (global_min, _) = local_to_global_dict[axis];
    global_start = global_start if global_start is not None else 0;
    global_stop = global_stop if global_stop is not None else globalshape[axis];
    local_start = global_start - global_min;
    local_stop = global_stop - global_min;
    return slice(local_start, local_stop, global_step);
}