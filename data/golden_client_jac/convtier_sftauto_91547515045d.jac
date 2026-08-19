def is_prime(num: Any) -> object {
    if (num <= 1) {
        return "Composite";
    }
    for i in range(2, (int(math.sqrt(num)) + 1)) {
        if ((num % i) == 0) {
            return "Composite";
        }
    }
    return "Prime";
}



with entry {
    print(is_prime(0));
}
