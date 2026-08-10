"""
Round income to the lower 10000th
Intput:
- income
Output:
- lower 10000th of the income. Return 0 if the income
is less than 30,000 or more than 120,000
"""
def round_income(x: int) -> int {
    for y in range(30, 130, 10) {
        if x >= y * 1000 and x < (y + 10) * 1000 {
            return y * 1000;
        }
    }
    return 0;
}