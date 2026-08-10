"""converts a number x to a golomb-encoded array of 0's and 1's"""
def encode_golomb(x: int, p: int) -> list[int | bool] {
    q = x >> p;
    result = ([1] * q) + [0];
    result += [(x & (1 << (p - i - 1))) > 0 for i in range(p)];
    return result;
}