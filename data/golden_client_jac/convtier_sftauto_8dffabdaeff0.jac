def calculate_sum(arr: Any) -> object {
    retrieved_elements = arr[2:5];
    sum_of_elements = sum(retrieved_elements);
    if (sum_of_elements >= 100) {
        return sum_of_elements;
    } else {
        return (sum_of_elements / 10);
    }
}



with entry {
    print(calculate_sum([]));
    print(calculate_sum([21, -3, -6, -12]));
}
