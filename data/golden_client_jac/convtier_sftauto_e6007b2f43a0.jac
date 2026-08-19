def calculate_percentage(arr: Any) -> object {
    count = 0;
    for num in arr {
        if (((num % 2) == 0) and ((num % 3) == 0) and (num > 10)) {
            count += 1;
        }
    }
    percentage = round(((count / len(arr)) * 100), 2);
    return percentage;
}



with entry {
    print(calculate_percentage([6, -12]));
}
