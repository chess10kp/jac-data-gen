def reverseString(s: Any) -> object {
    def reverseHelper(s: Any, i: Any) -> object {
        if (i == (len(s) - 1)) {
            return s[i];
        }
        return (reverseHelper(s, (i + 1)) + s[i]);
    }
    return reverseHelper(s, 0);
}



with entry {
    print(reverseString('hello'));
    print(reverseString('Racecar'));
    print(reverseString('abcabc'));
}
