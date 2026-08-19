def bubble_sort(numbers: Any) -> object {
    n = len(numbers);
    for i in range(n) {
        for j in range(0, (n - i - 1)) {
            if (numbers[j] > numbers[(j + 1)]) {
                (numbers[j], numbers[(j + 1)]) = (numbers[(j + 1)], numbers[j]);
            }
        }
    }
    return numbers;
}



with entry {
    print(bubble_sort([1, 2, 4]));
    print(bubble_sort([1, 2]));
    print(bubble_sort([5, 5, 5]));
}
