"""Tries to read an option from a dictionary. If not found, a
    standard value is returned instead. If no standard value is
    informed, None is returned. Data can also be converted by
    a type cast.
    The given standard value is not converted by typecast.
    """
def read_optional_from_dict[T](
    input_dict: dict[str, T],
    key: str,
    standard_val: T | None = None,
    typecast: type | None = None
) -> T | None {
    try {
        val = input_dict[key];
    } except KeyError {
        return standard_val;
    }
    if typecast is None {
        return val;
    }
    return typecast(val);
}