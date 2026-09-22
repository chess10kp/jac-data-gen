"""JSON serializer for objects not serializable by default json code."""
def serialize(`obj: object) -> dict[str, str | int | float | bool] | str {
    if getattr(`obj, '__dict__', False) {
        return `obj.__dict__;
    }
    return str(`obj);
}