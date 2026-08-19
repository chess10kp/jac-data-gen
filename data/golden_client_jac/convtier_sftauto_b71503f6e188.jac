def contains_all_vowels_in_order(string: Any) -> object {
    vowels = "aeiou";
    vowel_index = 0;
    for char in string {
        if (char.lower() == vowels[vowel_index]) {
            vowel_index += 1;
            if (vowel_index == len(vowels)) {
                return True;
            }
        }
    }
    return False;
}



with entry {
    print(contains_all_vowels_in_order('hello'));
}
