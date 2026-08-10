"""
    Create a list of unique items in transaction data.
    Represent each item as a set of length 1.
    """
def create_c1(dataset: list[list[int | str]]) -> list[frozenset[int | str]] {
    c: list[list[int | str]] = [];
    for data in dataset {
        for item in data {
            if [item] not in c {
                c.append([item]);
            }
        }
    }
    c.sort();
    return list(map(frozenset, c));
}