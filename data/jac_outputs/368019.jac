"""Calculate the nth fibonacci number using the seeds a and b"""
def fib1(a: int, b: int, n: int) -> int {
    if n == 1 {
        return a;
    } elif n == 2 {
        return b;
    } else {
        return fib1(a, b, n - 1) + fib1(a, b, n - 2);
    }
}