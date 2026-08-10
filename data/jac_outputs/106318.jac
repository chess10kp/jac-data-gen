"""Returns the types of return arguments in a tuple format."""
def get_return_types_as_tuple(arg_id_to_dtype: dict[int, type]) -> tuple[type, ...] {
    return_arg_id_to_dtype = {
        id: dtype
        for (id, dtype) in arg_id_to_dtype.items()
        if isinstance(id, int) and id < 0
    };
    return_arg_pos = sorted(return_arg_id_to_dtype.keys(), reverse=True);
    return tuple(return_arg_id_to_dtype[id] for id in return_arg_pos);
}