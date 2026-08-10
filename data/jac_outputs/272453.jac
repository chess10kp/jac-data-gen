"""Filter out duplicate donor acceptor atom pairs."""
def filter_duplicates(donors: list[int], acceptors: list[int]) -> tuple[list[int], list[int]] {
    pairs = sorted(list(set([(d, acceptors[idx]) for (idx, d) in enumerate(donors)])));
    new_donors = [pair[0] for pair in pairs];
    new_acceptors = [pair[1] for pair in pairs];
    return (new_donors, new_acceptors);
}