"""Get next element of iterator and call a custom function when failing """
def next_with_custom_error(iterator: Iterator[object], custom_error: Callable[[Exception], None], *args: object) -> object | None {
    try {
        return next(iterator, None);
    } except Exception as error {
        custom_error(error, *args);
        raise Exception(error);
    }
}