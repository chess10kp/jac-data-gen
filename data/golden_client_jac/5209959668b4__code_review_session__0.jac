import math;

def hypotenuse(a: float, b: float) -> float {
    return math.sqrt(a ** 2.0 + b ** 2.0);
}

with entry {
    print(f"hypotenuse(3, 4) = {hypotenuse(3.0, 4.0)}");
}
