def calculate_mean(numbers: Any) -> object {
    mean = sum(numbers) / len(numbers);
    return mean;
}



with entry {
    print(calculate_mean([81]));
    print(calculate_mean([100]));
    print(calculate_mean([-8, -4, 2]));
}
