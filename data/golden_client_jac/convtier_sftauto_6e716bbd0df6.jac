def get_descending_primes(originalList: Any) -> object {
    primes = [];
    for num in originalList {
        if (num > 1) {
            for i in range(2, (int((num / 2)) + 1)) {
                if ((num % i) == 0) {
                    break;
                }
            } else {
                primes.append(num);
            }
        }
    }
    return sorted(primes, reverse=True);
}



with entry {
    print(get_descending_primes([-9]));
    print(get_descending_primes([-8, -4, 2, 6]));
    print(get_descending_primes([4, 7, -1, 9, -2]));
}
