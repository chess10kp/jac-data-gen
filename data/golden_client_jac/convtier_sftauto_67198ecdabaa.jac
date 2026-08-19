def contains_only_vowels(str: Any) -> object {
    vowels = `set('aeiou');
    for char in str {
        if (char.lower() not in vowels) {
            return False;
        }
    }
    return True;
}



with entry {
    print(contains_only_vowels('hello'));
    print(contains_only_vowels([]));
}
