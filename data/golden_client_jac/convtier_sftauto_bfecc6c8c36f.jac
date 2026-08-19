def calculate_sum(lst: Any) -> object {
    total_sum = 0;
    for item in lst {
        if isinstance(item, `list) {
            total_sum += calculate_sum(item);
        } elif isinstance(item, float) {
            total_sum += round(item);
        } else {
            total_sum += item;
        }
    }
    return total_sum;
}



with entry {
    print(calculate_sum([81]));
    print(calculate_sum([]));
    print(calculate_sum([100]));
}
