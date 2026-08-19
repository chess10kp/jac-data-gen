def cumulative_sum(lst: Any) -> object {
    positive_numbers = [
        num
        for num in lst
        if (num > 0)
    ];
    positive_numbers = [
        num
        for num in positive_numbers
        if ((num % 3) != 0)
    ];
    cumulative_sum = [];
    current_sum = 0;
    for num in positive_numbers[::-1] {
        current_sum += num;
        cumulative_sum.append(current_sum);
    }
    return cumulative_sum;
}



with entry {
    print(cumulative_sum([]));
}
