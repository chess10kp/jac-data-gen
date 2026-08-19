def convert_string(n: Any) -> object {
    arr = ["hello"] * n;
    vowels = ['a', 'e', 'i', 'o', 'u'];
    for i in range(n) {
        converted_str = '';
        for char in arr[i] {
            if (char.lower() in vowels) {
                converted_str += char.upper();
            } else {
                converted_str += char.lower();
            }
        }
        arr[i] = converted_str;
    }
    return arr;
}



with entry {
    print(convert_string(5));
    print(convert_string(10));
    print(convert_string(2));
}
