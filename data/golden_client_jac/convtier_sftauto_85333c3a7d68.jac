def filter_and_sum(numbers: Any) -> object {
    filtered_numbers = [];
    for num in numbers {
        if (100 < num < 1000) {
            filtered_numbers.append(num);
        }
    }
    filtered_numbers.sort(reverse=True);
    sum_of_square_roots = 0;
    for num in filtered_numbers {
        sum_of_square_roots += math.sqrt(num);
    }
    return round(sum_of_square_roots, 10);
}



with entry {
    print(filter_and_sum([81]));
}
