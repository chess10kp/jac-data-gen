def is_palindrome(num: Any) -> object {
    reverse = 0;
    temp = num;
    while (temp > 0) {
        reverse = (reverse * 10) + (temp % 10);
        temp = temp // 10;
    }
    return (num == reverse);
}



with entry {
    print(is_palindrome(5));
    print(is_palindrome(10));
}
