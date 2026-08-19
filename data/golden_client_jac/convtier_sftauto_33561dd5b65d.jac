def sum_of_cubes(n: Any) -> object {
    total = 0;
    while (n > 0) {
        digit = n % 10;
        total += digit ** 3;
        n //= 10;
    }
    return total;
}



with entry {
    print(sum_of_cubes(5));
    print(sum_of_cubes(10));
    print(sum_of_cubes(2));
}
