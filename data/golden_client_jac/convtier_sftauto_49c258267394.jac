def compute_average(lst: Any) -> object {
    if (len(lst) == 0) {
        return 0;
    }
    total = 0;
    for num in lst {
        total += num;
    }
    return (total / len(lst));
}



with entry {
    print(compute_average([]));
}
