def calculate_average(arr: Any) -> object {
    if (len(arr) == 0) {
        return 0;
    }
    total = 0;
    for num in arr {
        total += num;
    }
    average = total / len(arr);
    return average;
}



with entry {
    print(calculate_average([7, 2]));
    print(calculate_average([2]));
    print(calculate_average([34]));
}
