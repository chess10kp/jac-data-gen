def find_primes(nums: List[int]) -> List[int] {
    primes = [];
    for num in nums {
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
    return primes;
}



with entry {
    print(find_primes([81]));
    print(find_primes([-8, -4, 2]));
    print(find_primes([-2, -1, -4, 7]));
}
