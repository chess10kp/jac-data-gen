def shell_sort(arr: Any) -> object {
    n = len(arr);
    gap = n // 2;
    while (gap > 0) {
        for i in range(gap, n) {
            temp = arr[i];
            j = i;
            while ((j >= gap) and (arr[(j - gap)] > temp)) {
                arr[j] = arr[(j - gap)];
                j -= gap;
            }
            arr[j] = temp;
        }
        gap = gap // 2;
    }
    return arr;
}



with entry {
    print(shell_sort([2, 9]));
    print(shell_sort([2]));
    print(shell_sort([34]));
}
