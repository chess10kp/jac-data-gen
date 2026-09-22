"""Returns tuple value at the given index."""
def tuple_filter[T](tuple_obj: tuple, index: int | str | float | bool) -> T | None {
    try {
        index = int(index);
    } except ValueError {
        return None;
    }
    if isinstance(tuple_obj, tuple) {
        try {
            return tuple_obj[index];
        } except IndexError {
            return None;
        }
    } else {
        return None;
    }
}