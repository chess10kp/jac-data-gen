def countVowels(s: Any) -> object {
    if not isinstance(s, str) {
        raise TypeError("Input must be a string");
    }
    if not s {
        return 0;
    }
    vowels = "aeiouAEIOU";
    count = 0;
    for char in s {
        if (char in vowels) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(countVowels('hello'));
    print(countVowels('Racecar'));
    print(countVowels('step on no pets'));
}
