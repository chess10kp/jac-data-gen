def normalizer(value: float | int | None, max_value: float | int) -> float {
    if value is None {
        return 0.0;
    }
    if value >= max_value {
        return 1.0;
    }
    return float(value) / float(max_value);
}