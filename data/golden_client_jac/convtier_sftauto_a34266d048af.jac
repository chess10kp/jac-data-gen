def shuffle(arr: Any) -> object {
    n = len(arr);
    for i in range((n - 1), 0, -1) {
        j = random.randint(0, i);
        (arr[i], arr[j]) = (arr[j], arr[i]);
    }
    return arr;
}



with entry {
    print(shuffle([]));
}
