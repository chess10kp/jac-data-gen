def sum_of_list(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        total += num;
    }
    return total;
}



with entry {
    print(sum_of_list([]));
}
