def sort_list(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        for j in range((i + 1), n) {
            if ((arr[i] ^ arr[j]) < 0) {
                arr[i] ^= arr[j];
                arr[j] ^= arr[i];
                arr[i] ^= arr[j];
            }
        }
    }
    return arr;
}



with entry {
    print(sort_list([81]));
    print(sort_list([]));
    print(sort_list(['a']));
}
