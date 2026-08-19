def extract_primes(arr: Any) -> object {
    prime_nums = [];
    for num in arr[:3] {
        if is_prime(num) {
            prime_nums.append(num);
        }
    }
    return prime_nums;
}



with entry {
    print(extract_primes([]));
}
