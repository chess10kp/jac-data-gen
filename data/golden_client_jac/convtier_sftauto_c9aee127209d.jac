def calculate_sum(array: Any) -> object {
    total = 0.0;
    for value in array {
        if ((value >= 0) and (value <= 100)) {
            total += value;
        }
    }
    return round(total, 2);
}



with entry {
    print(calculate_sum([81]));
    print(calculate_sum([]));
    print(calculate_sum([100]));
}
