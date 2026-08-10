"""
Tries to convert ``item`` to :py:func:float`. If it is not possible,
returns ``None``.
"""
def float_or_none(item: int | float | str | bool) -> float | None {
    if isinstance(item, float) {
        return item;
    }
    try {
        return float(item);
    } except Exception {
        return None;
    }
}