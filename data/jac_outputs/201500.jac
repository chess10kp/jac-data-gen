"""lcm: finds the least common multiple of two numbers"""
def lcm(num1: int, num2: int, limit: int = 10) -> int | None {
    num1ls = [num1];
    num2ls = [num2];
    for x in range(2, limit + 1) {
        num1ls.append(num1 * x);
        num2ls.append(num2 * x);
        if num1ls[-1] in num2ls {
            return num1ls[-1];
        } elif num2ls[-1] in num1ls {
            return num2ls[-1];
        }
    }
    return None;
}