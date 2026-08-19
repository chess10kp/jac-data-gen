def average_of_primes(lst: Any) -> object {
    primes = [];
    for num in lst {
        if (`type(num) == int) {
            if (num > 1) {
                for i in range(2, num) {
                    if ((num % i) == 0) {
                        break;
                    }
                } else {
                    primes.append(num);
                }
            }
        }
    }
    if (len(primes) == 0) {
        return -1;
    } else {
        return (sum(primes) / len(primes));
    }
}



with entry {
    print(average_of_primes('hello'));
    print(average_of_primes([1, 2, 4]));
    print(average_of_primes([5, 5, 5]));
}
