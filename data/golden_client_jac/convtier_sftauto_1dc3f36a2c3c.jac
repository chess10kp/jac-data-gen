def normalize_vector(vector: Any) -> object {
    total_sum = sum(vector);
    normalized_vector = [];
    for element in vector {
        normalized_element = element / total_sum;
        if (element < 0) {
            normalized_element = int(normalized_element);
        } else {
            normalized_element = int(normalized_element) + 1;
        }
        normalized_vector.append(normalized_element);
    }
    return normalized_vector;
}



with entry {
    print(normalize_vector([81]));
    print(normalize_vector([]));
    print(normalize_vector([-8, -4, 2]));
}
