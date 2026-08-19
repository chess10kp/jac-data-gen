def find_missing_element(arr: Any) -> object {
    missing = 0;
    for (i, num) in enumerate(arr) {
        missing ^= num;
        missing ^= i + 1;
    }
    return missing;
}



with entry {
    print(find_missing_element([81]));
    print(find_missing_element([]));
    print(find_missing_element([100]));
}
