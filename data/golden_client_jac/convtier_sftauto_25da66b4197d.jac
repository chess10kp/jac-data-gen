def even_sum(arr: Any) -> object {
    total = 0;
    for num in arr {
        if ((num % 2) == 0) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(even_sum([]));
    print(even_sum([6, -12]));
    print(even_sum([21, -3, -12, -6]));
}
