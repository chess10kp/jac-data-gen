def calculate_even_sum(arr: Any) -> object {
    sum = 0;
    for i in range(len(arr)) {
        if ((arr[i] % 2) == 0) {
            sum += arr[i];
        }
    }
    return sum;
}



with entry {
    print(calculate_even_sum([81]));
    print(calculate_even_sum([100]));
    print(calculate_even_sum([-8, -4, 2]));
}
