def find_average(arr: Any) -> object {
    total = 0;
    count = 0;
    for num in arr {
        total += num;
        count += 1;
    }
    if (count == 0) {
        return 0;
    }
    average = total / count;
    return round(average, 2);
}



with entry {
    print(find_average([]));
}
