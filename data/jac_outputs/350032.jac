"""Try, cast, handle."""
def safe_cast[T, U](value: T, __class: type, `default: U | None = None) -> U | None {
    try {
        return __class(value);
    } except (ValueError, TypeError) as err {
        print(f'Error casting {value} as {__class}: {err}');
        return `default;
    }
}