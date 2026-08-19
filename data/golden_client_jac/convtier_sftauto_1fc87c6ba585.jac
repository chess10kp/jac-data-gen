def quick_sort(arr: Any) -> object {
    stack = [(0, (len(arr) - 1))];
    while stack {
        (low, high) = stack.pop();
        if (low < high) {
            pivot_index = partition(arr, low, high);
            stack.append((low, (pivot_index - 1)));
            stack.append(((pivot_index + 1), high));
        }
    }
    return arr;
}



with entry {
    print(quick_sort([]));
}
