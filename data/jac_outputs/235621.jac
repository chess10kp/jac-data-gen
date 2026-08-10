"""Find index in string of number (possibly) with error bars immediately
before the decimal point."""
def find_last_dig(num_str: str) -> int {
    pos = num_str.find(".");
    assert pos != 0;
    if pos < 0 {
        pos = num_str.find("(");
        assert pos != 0;
    }
    if pos < 0 {
        pos = len(num_str);
        assert pos != 0;
    }
    return pos - 1;
}