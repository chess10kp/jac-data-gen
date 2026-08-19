def remove_odd_elements(arr: Any) -> object {
    i = 0;
    while (i < len(arr)) {
        if isinstance(arr[i], `list) {
            remove_odd_elements(arr[i]);
            i += 1;
        } elif isinstance(arr[i], int) {
            if ((arr[i] % 2) != 0) {
                arr.pop(i);
            } else {
                i += 1;
            }
        } else {
            arr.pop(i);
        }
    }
    return arr;
}



with entry {
    print(remove_odd_elements([]));
    print(remove_odd_elements([-10368, 1296]));
    print(remove_odd_elements([-10368, -126, 882]));
}
