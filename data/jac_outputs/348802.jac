"""
Check sequence start/end coordinates and return -1 for 3' strand,
1 for 5' strand.
"""
def get_strand(start: int, end: int) -> int {
    if start > end {
        return -1;
    } elif start <= end {
        return 1;
    }
    return 0;
}