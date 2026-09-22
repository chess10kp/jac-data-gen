"""
Generate an overlap table for the following prefix.
An overlap table is a table of the same size as the prefix which
informs about the potential self-overlap for each index in the prefix:
- if overlap[i] == 0, prefix[i:] can't overlap prefix[0:...]
- if overlap[i] == k with 0 < k <= i, prefix[i-k+1:i+1] overlaps with
  prefix[0:k]
"""
def _generate_overlap_table(prefix: str) -> list[int] {
    table = [0] * len(prefix);
    for i in range(1, len(prefix)) {
        idx = table[i - 1];
        while prefix[i] != prefix[idx] {
            if idx == 0 {
                table[i] = 0;
                break;
            }
            idx = table[idx - 1];
        } else {
            table[i] = idx + 1;
        }
    }
    return table;
}