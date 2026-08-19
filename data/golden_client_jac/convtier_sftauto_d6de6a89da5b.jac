def calculate_average(grades: Any) -> object {
    if (len(grades) == 0) {
        return -1;
    } else {
        total = sum(grades);
        average = total / len(grades);
        return round(average, 2);
    }
}



with entry {
    print(calculate_average([81]));
    print(calculate_average([]));
    print(calculate_average([100]));
}
