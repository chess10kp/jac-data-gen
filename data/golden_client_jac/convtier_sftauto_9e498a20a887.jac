def find_mean(numbers: Any) -> object {
    total = len(numbers);
    sum = 0;
    for num in numbers {
        sum += num;
    }
    mean = sum / total;
    return mean;
}



with entry {
    print(find_mean([-12, 6]));
    print(find_mean([-12, -6, -3, 21]));
}
