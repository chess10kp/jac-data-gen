def calculate_sum(lst: Any) -> object {
    sum = 0;
    for num in lst {
        if ((num % 2) != 0) {
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(calculate_sum([]));
}
