"""Return if d1_i <= d2_i as sparse vectors."""
def le_dtuple(d1: list[tuple[int, int]], d2: list[tuple[int, int]]) -> bool {
    d2_dict = dict(d2);
    return all(gen in d2_dict and exp <= d2_dict[gen] for (gen, exp) in d1);
}