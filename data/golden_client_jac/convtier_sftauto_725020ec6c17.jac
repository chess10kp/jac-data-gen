def find_prime_numbers(input_list: Any) -> object {
    primes = [
        x
        for x in input_list
        if (all(((x % i) != 0) for i in range(2, (int((x ** 0.5)) + 1))) and (x > 1))
    ];
    primes = `list(`set(primes));
    return primes;
}



with entry {
    print(find_prime_numbers([81]));
}
