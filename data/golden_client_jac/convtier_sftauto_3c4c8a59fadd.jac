def isPalindrome(s: Any) -> object {
    normalizedStr = s.lower();
    filteredStr = ''.join(
        ch
        for ch in normalizedStr
        if ch.isalnum()
    );
    start = 0;
    end = len(filteredStr) - 1;
    while (start < end) {
        if (filteredStr[start] != filteredStr[end]) {
            return False;
        }
        start += 1;
        end -= 1;
    }
    return True;
}



with entry {
    print(isPalindrome('hello'));
    print(isPalindrome('Racecar'));
}
