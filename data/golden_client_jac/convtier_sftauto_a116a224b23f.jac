def shuffle_numbers(numbers: Any) -> object {
    shuffled_list = [];
    n = len(numbers);
    for i in range((n - 1), 0, -1) {
        rand_index = generate_random_number((i + 1));
        (numbers[i], numbers[rand_index]) = (numbers[rand_index], numbers[i]);
    }
    return numbers;
}



with entry {
    print(shuffle_numbers([]));
}
