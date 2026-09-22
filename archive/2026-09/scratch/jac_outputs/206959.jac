"""
    Get the most square shape for the plot axes values.
    If only one factor, increase size and allow for empty slots.
    """
def subplot_shape(size: int) -> list[int] {
    facts = [
        [i, size // i]
        for i in range(1, int(size ** 0.5) + 1)
        if size % i == 0
    ];
    while len(facts) == 1 {
        size += 1;
        facts = [
            [i, size // i]
            for i in range(1, int(size ** 0.5) + 1)
            if size % i == 0
        ];
    }
    sum_facts = [sum(i) for i in facts];
    smallest = min(sum_facts);
    shape = facts[sum_facts.index(smallest)];
    return shape;
}