def count_unique_vowels(list_of_strings: Any) -> object {
    vowels = `set(['a', 'e', 'i', 'o', 'u']);
    concatenated_string = ''.join(list_of_strings).lower();
    unique_vowels = `set(
        [
            c
            for c in concatenated_string
            if (c in vowels)
        ]
    );
    return len(unique_vowels);
}



with entry {
    print(count_unique_vowels('hello'));
    print(count_unique_vowels('abcabc'));
    print(count_unique_vowels([]));
}
