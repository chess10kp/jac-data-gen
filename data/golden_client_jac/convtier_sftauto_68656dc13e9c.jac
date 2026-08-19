def calculate_mean(arr: Any) -> object {
    n = len(arr);
    total = 0;
    for num in arr {
        total += num;
    }
    return (total / n);
}



with entry {
    print(calculate_mean([81]));
    print(calculate_mean([100]));
    print(calculate_mean([-8, -4, 2]));
}
