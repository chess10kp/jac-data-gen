"""
	Three-way-partisions a sequence.

	Partitions a sequence of values consisting of three distinct different
	types of elements such that the resulting sequence is sorted.

	Loop invariants:

	1. All values to the left of i are of type 'left'
	2. All values to the right of n are of type 'right'
	3. Values after j have not been looked at.
	4. j <= n for all iterations.

	Makes at most N swaps.

	Arguments:
		seq (iterable): The sequence to partition.
		left: The first category, will end up on the left.
		right: The third category, will end up on the right.

	Returns:
		The sorted (three-way-partitioned) sequence.
	"""
def three_way_partition(seq: list[int], left: int, right: int) -> list[int] {
    i = 0;
    j = 0;
    n = len(seq) - 1;
    while j <= n {
        value = seq[j];
        if value == left {
            (seq[i], seq[j]) = (seq[j], seq[i]);
            i += 1;
            j += 1;
        } elif value == right {
            (seq[j], seq[n]) = (seq[n], seq[j]);
            n -= 1;
        } else {
            j += 1;
        }
    }
    return seq;
}