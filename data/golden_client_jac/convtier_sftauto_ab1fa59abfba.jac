def sum_of_two_largest_numbers(arr: Any) -> object {
    arr.sort();
    return (arr[-1] + arr[-2]);
}



with entry {
    print(sum_of_two_largest_numbers([-12, 6]));
    print(sum_of_two_largest_numbers([-12, -6, -3, 21]));
}
