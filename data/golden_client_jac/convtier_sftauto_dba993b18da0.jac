def mean(arr: Any) -> object {
    if (len(arr) == 0) {
        return None;
    }
    sum = 0;
    for i in range(len(arr)) {
        sum += arr[i];
    }
    return (sum / len(arr));
}



with entry {
    print(mean([-12, 6]));
    print(mean([-12, -6, -3, 21]));
}
