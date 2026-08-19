def calculate_sum(lst: Any) -> object {
    total_sum = 0;
    for num in lst {
        total_sum += num;
    }
    return total_sum;
}



with entry {
    print(calculate_sum([]));
}
