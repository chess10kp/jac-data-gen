"""shall be implemented in constant time (so NOT like it is now)"""
def cswap(swap: bool, x_2: int | str | float, x_3: int | str | float) -> tuple[int | str | float, int | str | float] {
    if swap {
        tmp = x_2;
        x_2 = x_3;
        x_3 = tmp;
    }
    return (x_2, x_3);
}