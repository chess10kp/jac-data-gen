def flatten_and_sum(lst: Any) -> object {
    if isinstance(lst, int) {
        return lst;
    } else {
        sum = 0;
        for elem in lst {
            sum += flatten_and_sum(elem);
        }
        return sum;
    }
}



with entry {
    print(flatten_and_sum(5));
    print(flatten_and_sum(10));
    print(flatten_and_sum(2));
}
