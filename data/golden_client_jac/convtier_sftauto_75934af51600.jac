def sum_of_elements(arr: Any) -> object {
    total_sum = 0;
    for num in arr {
        if (((num % 3) == 0) and (num > 5) and (num < 100) and ('2' not in str(num))) {
            total_sum += num;
        }
    }
    return total_sum;
}



with entry {
    print(sum_of_elements([81]));
    print(sum_of_elements([]));
}
