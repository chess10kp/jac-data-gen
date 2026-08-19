def calculate_sum(arr: Any) -> object {
    total = 0;
    for num in arr {
        total += num;
    }
    return total;
}



with entry {
    print(calculate_sum([]));
}
