def generate_array(N: Any) -> object {
    result = [([0] * N) for _ in range(N)];
    for i in range(N) {
        result[i][i] = 1;
        for j in range(N) {
            if (j != i) {
                result[i][j] = 1;
                result[j][i] = 1;
            }
        }
    }
    return result;
}



with entry {
    print(generate_array(5));
    print(generate_array(10));
    print(generate_array(2));
}
