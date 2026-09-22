"""Gets two lists and returns set difference of the two lists.

If one of them is None (file loading error) then the return value is None.
"""
def compare_two_data_lists(data1: list | None, data2: list | None) -> int | None {
    if data1 is None or data2 is None {
        return None;
    }
    return len(set(data1).difference(data2));
}