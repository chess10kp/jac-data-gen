def find_minimum(arr: Any) -> object {
    n = len(arr);
    minimum = float('inf');
    for i in range(n) {
        for j in range(i, n) {
            for k in range(j, n) {
                minimum = min(minimum, arr[k]);
            }
        }
    }
    return minimum;
}



with entry {
    print(find_minimum([81]));
    print(find_minimum([]));
    print(find_minimum([100]));
}
