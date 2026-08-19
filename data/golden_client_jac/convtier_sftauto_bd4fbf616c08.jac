def sum_of_divisible_by_three(lst: Any) -> object {
    total = 0;
    for e in lst {
        if (isinstance(e, int) and ((e % 3) == 0)) {
            total += e;
        } elif isinstance(e, `list) {
            total += sum_of_divisible_by_three(e);
        }
    }
    return round(total, 2);
}



with entry {
    print(sum_of_divisible_by_three('hello'));
    print(sum_of_divisible_by_three([10, 20, 30]));
    print(sum_of_divisible_by_three([2, 4, 6, 8]));
}
