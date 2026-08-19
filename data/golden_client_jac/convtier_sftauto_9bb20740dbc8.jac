def is_palindrome(lst: Any) -> object {
    nums = [
        x
        for x in lst
        if isinstance(x, (int, float))
    ];
    return (nums == nums[::-1]);
}



with entry {
    print(is_palindrome('hello'));
}
