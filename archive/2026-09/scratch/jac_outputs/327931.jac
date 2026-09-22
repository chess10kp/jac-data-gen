"""Given a list that may include duplicates, return a list of unique items

Returns a list of [(x,index)] for each 'x' in listOfItems,
where index is the number of times we've seen 'x' before.
"""
def augmentToBeUnique(listOfItems: list[str] | None) -> list[tuple[str, int]] {
    counts: dict[str, int] = {};
    output: list[tuple[str, int]] = [];
    if listOfItems is None {
        return [];
    }
    for x in listOfItems {
        counts[x] = counts.setdefault(x, 0) + 1;
        output.append((x, counts[x] - 1));
    }
    return output;
}