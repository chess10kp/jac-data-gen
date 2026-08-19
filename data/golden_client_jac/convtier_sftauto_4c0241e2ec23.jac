def normalize_vector(vector: Any) -> object {
    vector_sum = sum(vector);
    normalized_vector = [round((x / vector_sum), 2) for x in vector];
    return normalized_vector;
}



with entry {
    print(normalize_vector([]));
}
