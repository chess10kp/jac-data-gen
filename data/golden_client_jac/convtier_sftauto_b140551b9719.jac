def average_temperature(temperatures: Any) -> object {
    if (len(temperatures) == 0) {
        raise ValueError("No temperatures provided.");
    }
    total = sum(temperatures);
    average = total / len(temperatures);
    return round(average);
}



with entry {
    print(average_temperature([1, 2, 3, 4]));
    print(average_temperature([5, 5, 5]));
    print(average_temperature([10, 20, 30]));
}
