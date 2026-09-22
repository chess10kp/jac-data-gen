"""Verify the lengths of guide and off target match returning the length."""
def check_len(wt: str, off: str) -> int {
    wt_len = len(wt);
    off_len = len(off);
    assert wt_len == off_len, "The lengths wt and off differ: wt = {}, off = {}".format(str(wt_len), str(off_len));
    return wt_len;
}