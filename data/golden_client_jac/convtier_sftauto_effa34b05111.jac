def multiply_values(lst: Any) -> object {
    if (len(lst) == 0) {
        raise ValueError("Input list cannot be empty");
    }
    if `any((x < 0) for x in lst) {
        raise ValueError("Input list cannot contain negative integers");
    }
    if (len(lst) == 1) {
        return [(lst[0] * 5)];
    }
    return ([(lst[0] * 5)] + multiply_values(lst[1:]));
}



with entry {
    print(multiply_values([81]));
    print(multiply_values([100]));
}
