def mean(arr: Any) -> object {
    n = len(arr);
    total = 0;
    for num in arr {
        total = total ^ num;
    }
    mean = total // n;
    return mean;
}



with entry {
    print(mean([81]));
    print(mean([100]));
    print(mean([-8, -4, 2]));
}
