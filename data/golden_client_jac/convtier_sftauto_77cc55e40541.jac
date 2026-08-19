def count_primes(numbers: Any) -> object {
    count = 0;
    for num in numbers {
        if (num > 1) {
            for i in range(2, (int((num / 2)) + 1)) {
                if ((num % i) == 0) {
                    break;
                }
            } else {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_primes([]));
}
