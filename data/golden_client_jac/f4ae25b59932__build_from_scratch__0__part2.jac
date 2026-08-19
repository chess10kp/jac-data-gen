def celsius_to_fahrenheit(c: float) -> float {
    return c * 9.0 / 5.0 + 32.0;
}

with entry {
    for c in [0.0, 100.0, 37.0, -40.0, 25.0] {
        print(celsius_to_fahrenheit(c));
    }
}
