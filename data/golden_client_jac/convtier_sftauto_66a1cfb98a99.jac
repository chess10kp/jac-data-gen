def calculate_harmonic_mean(numbers: Any) -> object {
    numbers = [
        num
        for num in numbers
        if (num > 0)
    ];
    if ((len(numbers) < 5) or (len(numbers) > 10)) {
        raise ValueError("List length should be between 5 and 10");
    }
    harmonic_sum = sum([(1 / num) for num in numbers]);
    harmonic_mean = len(numbers) / harmonic_sum;
    return harmonic_mean;
}



with entry {
    print(calculate_harmonic_mean([4, 2, 7, 1, 9]));
}
