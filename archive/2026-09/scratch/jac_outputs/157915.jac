"""Check if `subseq` is a substring of `seq`."""
def is_substring(subseq: str, seq: str) -> bool {
    n = len(seq);
    m = len(subseq);
    if m > n {
        return False;
    }
    j = 0;
    i = 0;
    while i < n {
        if seq[i] == subseq[j] {
            j += 1;
            if j == m {
                return True;
            }
        } elif j > 0 {
            j = 0;
            continue;
        } else {
            j = 0;
            if n - i <= m {
                return False;
            }
        }
        i += 1;
    }
    return False;
}