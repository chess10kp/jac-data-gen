"""Given two dicts, merge them into a new dict as a shallow copy. http://stackoverflow.com/a/26853961/2153744"""
def merge_two_dicts(x: dict[str, object], y: dict[str, object]) -> dict[str, object] {
    if not isinstance(x, dict) {
        x = dict();
    } elif not isinstance(y, dict) {
        y = dict();
    }
    z = x.copy();
    z.update(y);
    return z;
}