"""Return 10^n: 10^n > num; 10^(n-1) <= num."""
def nifty_power_of_ten(num: int) -> int {
    result = 10;
    while result <= num {
        result *= 10;
    }
    return result;
}