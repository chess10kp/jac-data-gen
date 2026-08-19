def has_odd_number_of_odds(numbers: Any) -> object {
    odd_count = 0;
    for num in numbers {
        if ((num % 2) != 0) {
            odd_count += 1;
        }
    }
    return ((odd_count % 2) != 0);
}



with entry {
    print(has_odd_number_of_odds([]));
}
