"""One-hot embedding"""
def onek_encoding_unk[T](x: T, allowable_set: list[T]) -> list[int] {
    if x not in allowable_set {
        x = allowable_set[-1];
    }
    return [int(x == s) for s in allowable_set];
}