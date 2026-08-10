"""Convenience function to explicitly return a "value" specification for a DataSpec property."""
def value(val: str | int | float, transform: dict | None = None) -> dict {
    if transform {
        return {"value": val, "transform": transform};
    }
    return {"value": val};
}