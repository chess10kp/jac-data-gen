def sum_of_squares_of_evens(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        if ((num % 2) == 0) {
            total += num ** 2;
        }
    }
    return total;
}



with entry {
    print(sum_of_squares_of_evens([]));
}
