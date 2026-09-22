"""
Count unique name combinations from the lists in each dictionary entry.
"""
def count_possibilities(dic: dict[str, list[str]]) -> int {
    total = 1;
    for (_, value) in dic.items() {
        total *= len(value);
    }
    return total;
}