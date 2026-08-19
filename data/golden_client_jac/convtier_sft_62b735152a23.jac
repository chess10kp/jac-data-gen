def clamp(value: float, low: float, high: float) -> float {
    if value < low { return low; }
    if value > high { return high; }
    return value;
}

with entry {
    print(clamp(15.0, 0.0, 10.0));
}
