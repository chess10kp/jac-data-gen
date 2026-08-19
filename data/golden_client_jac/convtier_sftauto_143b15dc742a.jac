def find_no_consecutive_ones_indices(n: Any) -> object {
    binary = bin(n)[2:];
    indices = [];
    for i in range((len(binary) - 1)) {
        if ((binary[i] == '1') and (binary[(i + 1)] == '1')) {
            continue;
        }
        indices.append(i);
    }
    return indices;
}



with entry {
    print(find_no_consecutive_ones_indices(5));
    print(find_no_consecutive_ones_indices(10));
    print(find_no_consecutive_ones_indices(2));
}
