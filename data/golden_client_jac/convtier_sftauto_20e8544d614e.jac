def sum_even_numbers(lst: Any) -> object {
    return sum(
        x
        for x in lst
        if ((x % 2) == 0)
    );
}



with entry {
    print(sum_even_numbers([]));
    print(sum_even_numbers([6, -12]));
    print(sum_even_numbers([21, -3, -6, -12]));
}
