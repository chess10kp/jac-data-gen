def calculate_average(array: Any) -> object {
    if not array {
        return 0;
    }
    total_sum = sum(array);
    average = total_sum / len(array);
    return average;
}



with entry {
    print(calculate_average(0));
}
