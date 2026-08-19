def find_median(arr: Any) -> object {
    if not arr {
        return None;
    }
    arr.sort();
    length = len(arr);
    mid_index = length // 2;
    if ((length % 2) == 0) {
        return ((arr[(mid_index - 1)] + arr[mid_index]) / 2.0);
    }
    return arr[mid_index];
}



with entry {
    print(find_median([-10368, 1296]));
    print(find_median([-10368, -1296, -126, 882]));
}
