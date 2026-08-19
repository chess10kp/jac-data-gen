def round2(x: float) -> float {
    return int(x * 100.0 + 0.5) / 100.0;
}

with entry {
    for x in [3.14159, 2.71828, 1.41421, 0.5, 9.999] {
        print(round2(x));
    }
}
