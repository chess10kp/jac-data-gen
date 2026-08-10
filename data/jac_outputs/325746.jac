"""Convert a string value to a float, handling blank values."""
def get_float(fields: Any, key: Any) -> object {
    value = fields[key];
    try {
        value = float(value);
    } except ValueError {
        value = 0.0;
    }
    return value;
}