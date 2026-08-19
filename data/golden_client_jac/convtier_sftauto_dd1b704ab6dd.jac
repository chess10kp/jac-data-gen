def sum_even_numbers(numbers: Any) -> object {
    if (len(numbers) == 0) {
        return 0;
    } elif ((numbers[0] % 2) == 0) {
        return (numbers[0] + sum_even_numbers(numbers[1:]));
    } else {
        return sum_even_numbers(numbers[1:]);
    }
}



with entry {
    print(sum_even_numbers([]));
}
