def group_and_sort(numbers: Any) -> object {
    numbers = `list(`set(numbers));
    groups = [[] for _ in range(10)];
    for num in numbers {
        last_digit = num % 10;
        groups[last_digit].append(num);
    }
    for i in range(10) {
        groups[i].sort();
    }
    return groups;
}



with entry {
    print(group_and_sort([81]));
    print(group_and_sort([]));
    print(group_and_sort([100]));
}
