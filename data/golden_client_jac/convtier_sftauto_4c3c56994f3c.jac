def sum_greater_than_three(lst: Any) -> object {
    total_sum = 0;
    for sublist in lst {
        for value in sublist {
            if (value > 3) {
                total_sum += value;
            }
        }
    }
    return total_sum;
}



with entry {
    print(sum_greater_than_three([]));
}
