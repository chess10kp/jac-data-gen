def sum_divisible_by_three(lst: Any) -> object {
    if (len(lst) == 0) {
        return 0;
    }
    if ((lst[0] % 3) == 0) {
        return (lst[0] + sum_divisible_by_three(lst[1:]));
    } else {
        return sum_divisible_by_three(lst[1:]);
    }
}



with entry {
    print(sum_divisible_by_three([]));
}
