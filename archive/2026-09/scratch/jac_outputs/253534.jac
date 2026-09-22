""" Returns initialisation wavelength and termination wavelength """
def _limits(band: str) -> tuple[float, float] {
    limits = {
        'g': (3990.0, 5440.0),
        'r': (5440.0, 6960.0),
        'i': (6960.0, 8500.0),
        'z': (8500.0, 9320.0),
        'y': (9320.0, 10760.0)
    };
    return limits[band];
}