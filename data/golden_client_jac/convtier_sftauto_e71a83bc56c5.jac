def count_even_before_odd(arr: Any) -> object {
    count = 0;
    for num in arr {
        if ((num % 2) == 0) {
            count += 1;
        } else {
            break;
        }
    }
    return count;
}



with entry {
    print(count_even_before_odd([]));
}
