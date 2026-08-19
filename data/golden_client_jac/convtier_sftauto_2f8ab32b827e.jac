def generate_string(numbers: Any) -> object {
    result = [];
    for num in numbers {
        if (num >= 0) {
            result.append(("Number: " + str(num)));
        }
    }
    return ", ".join(result);
}



with entry {
    print(generate_string([81]));
    print(generate_string([]));
    print(generate_string([100]));
}
