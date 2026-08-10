def reverse(x: int) -> int {
    sum1 = 0;
    if x > 0 {
        n = len(str(x));
        for i in range(n) {
            rem = x % 10;
            x = x // 10;
            sum1 = sum1 * 10 + rem;
        }
        return sum1;
    } elif x < 0 {
        x = x * -1;
        n = len(str(x));
        for i in range(n) {
            rem = x % 10;
            x = x // 10;
            sum1 = sum1 * 10 + rem;
        }
        return sum1 * -1;
    } else {
        return x;
    }
}