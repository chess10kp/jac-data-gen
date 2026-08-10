"""a_(i+1) = func_g(a_i, x_i)"""
def func_g(a: int, n: int, p: int, x_i: int) -> int {
    match x_i % 3 {
        case 2:
            return a;
        case 0:
            return (2 * a) % n;
        case 1:
            return (a + 1) % n;
        case _:
            print("[-] Something's wrong!");
            return -1;
    }
}