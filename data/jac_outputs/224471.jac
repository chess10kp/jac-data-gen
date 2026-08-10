"""Convert the input parameter into a boolean."""
def str2bool(v: str) -> bool {
    if isinstance(v, bool) {
        return v;
    }
    if v.lower() in ('yes', 'true', 't', 'y', '1') {
        return True;
    } elif v.lower() in ('no', 'false', 'f', 'n', '0') {
        return False;
    } else {
        raise ValueError('Boolean value expected.');
    }
}