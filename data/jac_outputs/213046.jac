"""Convert color temperature in Kelvin to RGB values."""
def kelvin_to_rgb(K: int) -> tuple[float, float, float] {
    table = {
        4000: (1.0, 0.6636, 0.3583),
        5000: (1.0, 0.7992, 0.6045),
        6000: (1.0, 0.9019, 0.8473),
        7000: (0.9337, 0.915, 1.0),
        8000: (0.7874, 0.8187, 1.0),
        9000: (0.6693, 0.7541, 1.0),
        0: (1, 1, 1)
    };
    return table[K];
}