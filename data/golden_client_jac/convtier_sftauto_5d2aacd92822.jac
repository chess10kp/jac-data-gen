def find_prime_numbers(numbers: Any) -> object {
    prime_numbers = [];
    for num in numbers {
        if (num > 100) {
            is_prime = True;
            for i in range(2, (int(math.sqrt(num)) + 1)) {
                if ((num % i) == 0) {
                    is_prime = False;
                    break;
                }
            }
            if is_prime {
                prime_numbers.append(num);
            }
        }
    }
    prime_numbers.sort();
    return prime_numbers;
}



with entry {
    print(find_prime_numbers([]));
}
