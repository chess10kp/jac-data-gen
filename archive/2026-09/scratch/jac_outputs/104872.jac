"""Split N into M pieces. See https://stackoverflow.com/a/26554699/9746916."""
def split_NtoM(N: int, M: int, rank: int) -> tuple[int, int] {
    chunk = N // M;
    remainder = N % M;
    if rank < remainder {
        start = rank * (chunk + 1);
        stop = start + chunk;
    } else {
        start = rank * chunk + remainder;
        stop = start + chunk - 1;
    }
    return (start, stop);
}