"""
b_(i+1) = func_g(b_i, x_i)
"""
def func_h(b: int, n: int, p: int, x_i: int) -> int {
    match x_i % 3 {
        case 2:
            return (b + 1) % n;
        case 0:
            return (2 * b) % n;
        case 1:
            return b;
        case _:
            print("[-] Something's wrong!");
            return -1;
    }
}