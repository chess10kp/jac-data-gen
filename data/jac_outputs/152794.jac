""" works for all system sizes N. """
def translation(x: int, N: int, sign_ptr: int, args: list[int]) -> int {
    shift = args[0];
    period = N;
    xmax = args[1];
    l = (shift + period) % period;
    x1 = x >> (period - l);
    x2 = (x << l) & xmax;
    return x2 | x1;
}