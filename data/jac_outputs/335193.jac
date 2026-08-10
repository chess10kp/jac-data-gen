"""Convert a comma separated string of values to list of given type."""
def get_csv[T](csv: str, `type: Callable[[str], T]) -> list[T] {
    if `type == str {
        return [str(itm).strip() for itm in csv.split(',')];
    }
    return [`type(itm) for itm in csv.split(',')];
}