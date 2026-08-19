def count_vowels(text: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    ignored_consonant = 'r';
    count = 0;
    previous_char = '';
    for char in text {
        if ((char.lower() in vowels) and (previous_char != ignored_consonant)) {
            count += 1;
        }
        previous_char = char.lower();
    }
    return count;
}



with entry {
    print(count_vowels('hello'));
    print(count_vowels('Hello, World!'));
    print(count_vowels('step on no pets'));
}
