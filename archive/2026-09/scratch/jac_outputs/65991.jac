"""Returns the lowest common multiple of two given integers."""
def lcm(num1: int, num2: int) -> int {
    temp_num = num1;
    while temp_num % num2 != 0 {
        temp_num += num1;
    }
    return temp_num;
}