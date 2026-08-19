def count_prime_numbers(arr: Any) -> object {
    count = 0;
    for num in arr {
        if (num < 2) {
            continue;
        }
        is_prime = True;
        for i in range(2, (int((num ** 0.5)) + 1)) {
            if ((num % i) == 0) {
                is_prime = False;
                break;
            }
        }
        if is_prime {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_prime_numbers([1, 2, 4]));
    print(count_prime_numbers([5, 5, 5]));
    print(count_prime_numbers([10, 20, 30]));
}
