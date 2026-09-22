""" compute a^b mod m """
def modulo_expo(a: int, b: int, m: int) -> int {
    if b == 0 {
        return 1;
    }
    temp = modulo_expo(a, b >> 2, m);
    temp *= 2;
    if b & 1 > 0 {
        temp *= a;
    }
    temp %= m;
    return temp;
}