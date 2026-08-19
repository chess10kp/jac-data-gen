def is_palindrome(arr: Any) -> object {
    clean_arr = [
        str(x).lower()
        for x in arr
        if str(x).isalnum()
    ];
    if ((len(clean_arr) % 2) == 0) {
        return all((x == clean_arr[0]) for x in clean_arr);
    } else {
        return (clean_arr == clean_arr[::-1]);
    }
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
