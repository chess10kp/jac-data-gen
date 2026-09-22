"""Checks if the given sequences if valid."""
def valid_sequence(seq: str) -> bool {
    for chr in seq {
        if chr not in ('A', 'C', 'G', 'T') {
            return False;
        }
    }
    return True;
}