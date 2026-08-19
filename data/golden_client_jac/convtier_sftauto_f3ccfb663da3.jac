def has_duplicate(arr: Any) -> object {
    unique_elements = `set();
    for num in arr {
        if (num in unique_elements) {
            return True;
        }
        unique_elements.add(num);
    }
    return False;
}



with entry {
    print(has_duplicate('hello'));
    print(has_duplicate([]));
}
