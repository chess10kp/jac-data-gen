"""
Exponential Complexity

1. it's prevalent to think about size of smaller
2. Remember that for a set of size K there are pow(2, k) cases
3. To solve this we need something like pow(2, n-1) + pow(2, n-2) + ... + pow(2, 0)
"""
def gen_subsets(L: list[int]) -> list[list[int]] {
    if len(L) == 0 {
        return [[]];
    }
    smaller = gen_subsets(L[:-1]);
    extra = L[-1:];
    new = [];
    for small in smaller {
        new.append(small + extra);
    }
    return smaller + new;
}