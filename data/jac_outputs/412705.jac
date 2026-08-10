"""Unpack metric specification."""
def get_value(specs: list[dict[str, str | float]], name: str) -> float | None {
    value: float | None = None;
    for s in specs {
        if s['name'] == name {
            value = s['value'] as float;
            break;
        }
    }
    return value;
}