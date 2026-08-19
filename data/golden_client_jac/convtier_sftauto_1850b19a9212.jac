def swap_first_last(numbers: Any) -> object {
    if (len(numbers) > 1) {
        (numbers[0], numbers[-1]) = (numbers[-1], numbers[0]);
    }
    return numbers;
}



with entry {
    print(swap_first_last([]));
}
