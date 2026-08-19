def generate_pythagorean_triples(limit: Any) -> object {
    triples = [];
    for a in range(1, (limit + 1)) {
        for b in range((a + 2), (limit + 1), 2) {
            c = math.sqrt(((a ** 2) + (b ** 2)));
            if (
                (c == int(c))
                and (c <= limit)
                and ((a + b + c) <= 50)
                and is_prime((a * b * c))
                and is_divisible_by_3((a * b))
                and is_perfect_square((a + b + c))
            ) {
                triples.append((a, b, int(c)));
            }
        }
    }
    return triples;
}



with entry {
    print(generate_pythagorean_triples(2));
}
