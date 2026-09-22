"""Check that vec1 is less than vec2 elemtwise."""
def vec_leq(vec1: list[int], vec2: list[int]) -> bool {
    assert isinstance(vec1, list), "Only work with lists";
    assert isinstance(vec2, list), "Only work with lists";
    assert len(vec1) == len(vec2), "Vector lengths should be the same";
    for (x, y) in zip(vec1, vec2) {
        if x > y {
            return False;
        }
    }
    return True;
}