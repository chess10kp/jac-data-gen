"""Reads keyword arguments from input_dict using type_dict casts."""
def read_kwargs_from_dict(
    input_dict: dict[str, str | int | float],
    type_dict: dict[str, Callable[[str | int | float], str | int | float] | None]
) -> dict[str, str | int | float] {
    kwargs = dict();
    for (key, cast) in type_dict.items() {
        try {
            if cast is None {
                kwargs[key] = input_dict[key];
            } else {
                kwargs[key] = cast(input_dict[key]);
            }
        } except KeyError {
            ;
        }
    }
    return kwargs;
}