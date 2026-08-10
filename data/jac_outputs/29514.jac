"""Return the number of steps needed to calculate GCD(a, b)."""
def gcd_steps(a: int, b: int) -> int {
    steps = 0;
    while b != 0 {
        steps += 1;
        remainder = a % b;
        a = b;
        b = remainder;
    }
    return steps;
}