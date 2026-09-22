"""Gets sort key for the given name, when sorting attribute, method, or such names."""
def name_sort_key(name: str) -> tuple[int, str] {
    if name.startswith('__') {
        if name == '__new__' {
            prefix_count = 0;
        } elif name == '__init__' {
            prefix_count = 1;
        } elif name == '__call__' {
            prefix_count = 2;
        } else {
            prefix_count = 102;
        }
    } elif name.startswith('_') {
        prefix_count = 101;
    } else {
        prefix_count = 100;
    }
    return (prefix_count, name);
}