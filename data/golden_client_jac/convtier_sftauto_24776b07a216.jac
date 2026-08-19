def find_mistaken_min_index(arr: Any) -> object {
    n = len(arr);
    min_index = 0;
    max_index = 0;
    for i in range(1, n) {
        if (`abs(arr[i]) < `abs(arr[min_index])) {
            min_index = i;
        }
        if (`abs(arr[i]) >= `abs(arr[max_index])) {
            min_index = i;
            max_index = i;
        }
    }
    return min_index;
}



with entry {
    print(find_mistaken_min_index([81]));
    print(find_mistaken_min_index([-8, -4, 2]));
    print(find_mistaken_min_index([-2, -1, 4, 7]));
}
