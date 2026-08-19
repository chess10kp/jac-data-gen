def has_even_sum(lst: Any) -> object {
    running_sum = 0;
    for num in lst {
        running_sum += num;
        if ((running_sum % 2) != 0) {
            return False;
        }
    }
    return ((running_sum % 2) == 0);
}



with entry {
    print(has_even_sum([-9]));
    print(has_even_sum([]));
}
