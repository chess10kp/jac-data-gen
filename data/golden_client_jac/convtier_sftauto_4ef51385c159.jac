def get_array_size_in_bytes(array: Any) -> object {
    n = len(array);
    size_in_bytes = n * 8;
    return size_in_bytes;
}



with entry {
    print(get_array_size_in_bytes('hello'));
    print(get_array_size_in_bytes('Racecar'));
    print(get_array_size_in_bytes('abcabc'));
}
