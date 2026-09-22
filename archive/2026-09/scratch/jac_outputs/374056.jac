"""Maps inputs not in the allowable set to the last element."""
def onehot_encoding_unk(x: int, allowable_set: list[int]) -> list[bool] {
    if x not in allowable_set {
        x = allowable_set[-1];
    }
    return [(x == s) for s in allowable_set];
}