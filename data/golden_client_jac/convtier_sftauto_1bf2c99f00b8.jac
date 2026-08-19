def calculate_frequency(numbers: Any) -> object {
    frequency = {};
    for num in numbers {
        key = str(num);
        if (key in frequency) {
            frequency[key] += 1;
        } else {
            frequency[key] = 1;
        }
    }
    return frequency;
}



with entry {
    print(calculate_frequency('hello'));
    print(calculate_frequency('Racecar'));
    print(calculate_frequency('abcabc'));
}
