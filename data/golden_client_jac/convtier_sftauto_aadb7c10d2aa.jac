def calculate_mode(numbers: Any) -> object {
    frequency = {};
    for num in numbers {
        if (num in frequency) {
            frequency[num] += 1;
        } else {
            frequency[num] = 1;
        }
    }
    max_freq = max(frequency.values());
    modes = [
        num
        for (num, freq) in frequency.items()
        if (freq == max_freq)
    ];
    return modes;
}



with entry {
    print(calculate_mode('hello'));
    print(calculate_mode('Racecar'));
    print(calculate_mode('abcabc'));
}
