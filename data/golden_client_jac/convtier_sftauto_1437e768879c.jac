def find_sum(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        if not isinstance(num, (int, float)) {
            raise ValueError("Input list contains non-numeric values");
        }
        total += num;
    }
    return total;
}



with entry {
    print(find_sum([]));
}
