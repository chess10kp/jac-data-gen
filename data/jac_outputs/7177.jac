"""
    For curious people: regexes are very slow for parsing CIGAR strings.

    cigar: Unicode
    """
def count_cigar_ops(cigar: str) -> tuple[int, int, int, int] {
    b = 0;
    (num_m, num_i, num_d) = (0, 0, 0);
    for i in range(len(cigar)) {
        if cigar[i] <= '9' {
            continue;
        }
        assert b < i;
        count = int(cigar[b:i]);
        op = cigar[i];
        b = i + 1;
        if op == 'D' {
            num_d += count;
        } elif op == 'I' {
            num_i += count;
        } elif op in ('M', '=', 'X') {
            num_m += count;
        }
    }
    assert b == len(cigar);
    total_len = num_d + num_i + num_m;
    return (num_m, num_i, num_d, total_len);
}