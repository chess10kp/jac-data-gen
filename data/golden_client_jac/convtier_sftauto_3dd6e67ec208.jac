def calculate_average(arr: Any) -> object {
    total_sum = 0;
    count = 0;
    for num in arr {
        if (num >= 0) {
            total_sum += num;
            count += 1;
        }
    }
    if (count > 0) {
        average = round((total_sum / count));
        return average;
    } else {
        return 0;
    }
}



with entry {
    print(calculate_average([81]));
    print(calculate_average([]));
    print(calculate_average([100]));
}
