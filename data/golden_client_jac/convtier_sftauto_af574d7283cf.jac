def find_divisible_numbers(numbers: List[int]) -> List[int] {
    divisible_numbers = [];
    for num in numbers {
        if (((num % 3) == 0) and ((num % 7) == 0)) {
            divisible_numbers.append(num);
        }
    }
    return divisible_numbers;
}



with entry {
    print(find_divisible_numbers([]));
    print(find_divisible_numbers([21, -3, -6, -12]));
}
