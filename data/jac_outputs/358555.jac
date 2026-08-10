"""Gives the sum of all the positive numbers before input number."""
def sumNumber(num: int) -> int {
    sum_num = 0;
    for i in range(num + 1) {
        sum_num += i;
    }
    return sum_num;
}