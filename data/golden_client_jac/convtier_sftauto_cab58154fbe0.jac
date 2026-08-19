def scale_vector(input_vector: Any) -> object {
    scaling_factor = 1019 / 1000;
    output_vector = [];
    for num in input_vector {
        scaled_num = round((num * scaling_factor));
        output_vector.append(scaled_num);
    }
    return output_vector;
}



with entry {
    print(scale_vector([81]));
    print(scale_vector([]));
    print(scale_vector([100]));
}
