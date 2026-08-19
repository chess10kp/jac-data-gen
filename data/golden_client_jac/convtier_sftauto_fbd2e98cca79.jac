def create_array(n: Any) -> object {
    arr = [];
    for i in range((n - 1), -1, -1) {
        arr.append(i);
    }
    return arr;
}



with entry {
    print(create_array(5));
    print(create_array(10));
    print(create_array(2));
}
