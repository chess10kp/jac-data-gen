def multiply_sort(arr: Any) -> object {
    unique_elements = `set(arr);
    result = [];
    for num in unique_elements {
        if ((num % 2) == 0) {
            result.append((num * 3));
        }
    }
    return sorted(result, reverse=True);
}



with entry {
    print(multiply_sort([81]));
    print(multiply_sort([100]));
    print(multiply_sort([-8, -4, 2]));
}
