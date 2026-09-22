"""Get 'st', 'nd', 'rd' or 'th' as appropriate for an integer."""
def ordinal_suffix(i: Any) -> object {
    if (i < 0) {
        raise Exception("Can't handle negative numbers.");
    }
    if ((i % 100) in [11, 12, 13]) {
        return 'th';
    } elif ((i % 10) is 1) {
        return 'st';
    } elif ((i % 10) is 2) {
        return 'nd';
    } elif ((i % 10) is 3) {
        return 'rd';
    } else {
        return 'th';
    }
}