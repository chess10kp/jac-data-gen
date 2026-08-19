def jcos(a: float) -> float {
    x2 = a * a;
    return 1.0 - x2/2.0 + (x2*x2)/24.0 - (x2*x2*x2)/720.0;
}
