def sum_even_numbers(numbers: List[int]) -> int {
    return sum(
        num
        for num in numbers
        if ((num % 2) == 0)
    );
}



with entry {
    print(sum_even_numbers([81]));
    print(sum_even_numbers([100]));
    print(sum_even_numbers([-8, -4, 2]));
}
