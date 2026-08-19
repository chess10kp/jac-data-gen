def compute_sum(arr: Any) -> object {
    if (len(arr) == 0) {
        return 0;
    } elif (len(arr) == 1) {
        return arr[0];
    } else {
        return sum(arr);
    }
}



with entry {
    print(compute_sum([81]));
    print(compute_sum([]));
    print(compute_sum(['a']));
}
