def sum_prime_numbers(arr: Any) -> object {
    def is_prime(n: Any) -> object {
        if (n <= 1) {
            return False;
        }
        for i in range(2, (int((n ** 0.5)) + 1)) {
            if ((n % i) == 0) {
                return False;
            }
        }
        return True;
    }
    prime_sum = 0;
    for num in arr {
        if is_prime(num) {
            prime_sum += num;
        }
    }
    return prime_sum;
}



with entry {
    print(sum_prime_numbers([4, 3, 2, 1]));
    print(sum_prime_numbers([5, 5, 5]));
    print(sum_prime_numbers([10, 20, 30]));
}
