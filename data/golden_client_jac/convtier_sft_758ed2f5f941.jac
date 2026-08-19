def is_prime(n: int) -> bool {
    if n <= 1 { return False; }
    for i in range(2, int(n ** 0.5) + 1) {
        if n % i == 0 { return False; }
    }
    return True;
}

def sum_prime_numbers(nums: list[int]) -> int {
    total = 0;
    for num in nums {
        if is_prime(num) { total += num; }
    }
    return total;
}

with entry {
    print(sum_prime_numbers([2, 3, 4, 5, 6]));
}
