def count_even_before_odd(arr: Any) -> object {
    count_even = 0;
    for num in arr {
        if ((num % 2) == 0) {
            count_even += 1;
        } else {
            break;
        }
    }
    return count_even;
}



with entry {
    print(count_even_before_odd([81]));
    print(count_even_before_odd([100]));
    print(count_even_before_odd([-8, -4, 2]));
}
