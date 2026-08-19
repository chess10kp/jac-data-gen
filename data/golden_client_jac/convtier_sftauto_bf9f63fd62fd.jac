def generate_pythagorean_triples(limit: Any) -> object {
    triples = [];
    for a in range(1, (limit + 1)) {
        for b in range(a, (limit + 1)) {
            c = ((a ** 2) + (b ** 2)) ** 0.5;
            if (c.is_integer() and ((a + b + c) <= 50)) {
                triples.append((a, b, int(c)));
            }
        }
    }
    return triples;
}



with entry {
    print(generate_pythagorean_triples(5));
    print(generate_pythagorean_triples(10));
    print(generate_pythagorean_triples(2));
}
