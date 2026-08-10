"""Returns the complex impedance from z (in %) and the X/R ratio."""
def complex_impedance(z: int | float, XR: int | float) -> complex {
    z = float(abs(z));
    XR = float(abs(XR));
    real = (z ** 2 / (1 + XR ** 2)) ** 0.5;
    try {
        imag = (z ** 2 / (1 + 1 / XR ** 2)) ** 0.5;
    } except ZeroDivisionError {
        imag = 0.0;
    }
    return complex(real, imag);
}