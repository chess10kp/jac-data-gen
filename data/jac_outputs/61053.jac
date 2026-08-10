"""Compute factorial with optional step-by-step output."""
def fatorial(num: int, show: bool = False) -> int {
    print('-=' * 30);
    fat = 1;
    for c in range(num, 0, -1) {
        if show {
            print(c, end='');
            if c > 1 {
                print(f' x ', end='');
            } else {
                print(' = ', end='');
            }
        }
        fat *= c;
    }
    return fat;
}