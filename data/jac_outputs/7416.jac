"""Returns the largest palindrome made from the product of two 3-digit
numbers which is less than n.
"""
def solution(n: int) -> int | None {
    for number in range(n - 1, 10000, -1) {
        str_number = str(number);
        if str_number == str_number[::-1] {
            divisor = 999;
            while divisor != 99 {
                if number % divisor == 0 and len(str(int(number / divisor))) == 3 {
                    return number;
                }
                divisor -= 1;
            }
        }
    }
}