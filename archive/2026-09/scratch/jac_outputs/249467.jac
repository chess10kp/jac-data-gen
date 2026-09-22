"""Return Percent Of"""
def percentof(value1: float | int | None, value2: float | int | None) -> float {
    v1 = value1 or 0;
    v2 = value2 or 1;
    return (v1 / v2) * 100;
}