def find_array_sum(arr: Any) -> object {
    sum = 0;
    for num in arr {
        sum += num;
    }
    return sum;
}



with entry {
    print(find_array_sum([]));
}
