"""Scales the items in the vector, so that their sum is 1"""
def scale_to_sum_one(vector: list[int | float]) -> list[int | float] {
    total = sum(vector);
    if total == 0 {
        return vector;
    }
    return [v / total for v in vector];
}