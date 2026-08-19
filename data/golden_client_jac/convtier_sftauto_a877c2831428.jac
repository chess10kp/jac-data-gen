def sum_of_even_numbers(lst: Any) -> object {
    total = 0;
    for num in lst {
        if (isinstance(num, int) and ((num % 2) == 0)) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(sum_of_even_numbers('hello'));
    print(sum_of_even_numbers([100]));
    print(sum_of_even_numbers([-8, -4, 2]));
}
