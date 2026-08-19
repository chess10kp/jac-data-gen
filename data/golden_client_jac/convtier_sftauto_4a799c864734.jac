def is_palindrome(num: Any) -> object {
    num_str = str(num);
    start = 0;
    end = len(num_str) - 1;
    while (start <= end) {
        if (num_str[start] != num_str[end]) {
            return False;
        }
        start += 1;
        end -= 1;
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
