"""Return whether bytes x ends with the suffix subsequence."""
def bytes_endswith(x: bytes, suffix: bytes) -> bool {
    index = len(x) - len(suffix);
    if index < 0 {
        return False;
    }
    for i in suffix {
        if x[index] != i {
            return False;
        }
        index += 1;
    }
    return True;
}