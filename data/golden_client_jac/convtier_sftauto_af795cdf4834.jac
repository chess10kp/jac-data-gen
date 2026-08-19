def sum_even_elements(arr: Any) -> object {
    result = arr[0];
    for num in arr {
        if ((num % 2) == 0) {
            result += num;
        }
    }
    return (result * arr[0]);
}



with entry {
    print(sum_even_elements([2, 7]));
    print(sum_even_elements([34]));
    print(sum_even_elements([10, 20, 30]));
}
