"""
	Checks for existence of a bijection between input sequences
	seq1 and seq2.
	"""
def is_equivalent(seq1: list[int | str], seq2: list[int | str]) -> bool {
    letters1 = set(seq1);
    letters2 = set(seq2);
    distinct_mappings = set(zip(seq1, seq2));
    return len(letters1) == len(letters2) == len(distinct_mappings)
        and len(seq1) == len(seq2);
}