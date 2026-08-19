def is_unique_array(arr: Any) -> object {
    seen = `set();
    for num in arr {
        if (num in seen) {
            return False;
        }
        seen.add(num);
    }
    return True;
}



with entry {
    print(is_unique_array('hello'));
    print(is_unique_array([]));
}
