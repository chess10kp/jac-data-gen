"""Check we've a valid CSD number
Returns false if the array contains consequitive non-zero terms.
"""
def is_proper_csd(csd_num: str) -> bool {
    for i in range(1, len(csd_num)) {
        if (csd_num[i] != '0' and csd_num[i - 1] != '0') {
            return False;
        }
    }
    return True;
}