def translate_matrix(v: list) -> list {
    m = [1.0 if i % 5 == 0 else 0.0 for i in range(16)];
    m[12:15] = [v[0], v[1], v[2]];
    return m;
}

with entry {
    print(translate_matrix([2.0, 3.0, 4.0]));
}
