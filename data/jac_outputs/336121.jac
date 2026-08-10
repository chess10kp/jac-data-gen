"""Option sorter."""
def sorter(a: tuple[int, dict[str, int]], b: tuple[int, dict[str, int]]) -> int {
    if 'priority' not in a[1] and 'priority' not in b[1] {
        return 0;
    } elif 'priority' in a[1] and 'priority' not in b[1] {
        return -1;
    } elif 'priority' in b[1] and 'priority' not in a[1] {
        return 1;
    } elif a[1]['priority'] > b[1]['priority'] {
        return 1;
    } elif a[1]['priority'] == b[1]['priority'] {
        return 0;
    } else {
        return -1;
    }
}