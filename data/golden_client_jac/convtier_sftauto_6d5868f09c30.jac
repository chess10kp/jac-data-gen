def sum_positive_elements(arr: Any) -> object {
    total = 0;
    for num in arr {
        if (num >= 0) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(sum_positive_elements([]));
}
