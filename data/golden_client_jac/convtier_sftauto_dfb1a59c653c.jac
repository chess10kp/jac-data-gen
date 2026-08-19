def count_vowels(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    count = 0;
    string = string.lower();
    for char in string {
        if (char in vowels) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_vowels('hello'));
    print(count_vowels('Racecar'));
    print(count_vowels('step on no pets'));
}
