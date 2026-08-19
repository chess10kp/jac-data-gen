def convert_to_dictionary(lst: Any) -> object {
    vowels = ['A', 'E', 'I', 'O', 'U'];
    result = {};
    count = 1;
    for string in lst {
        if (
            (len(string) >= 3) and `any((vowel in string.upper()) for vowel in vowels)
        ) {
            result[count] = string.upper();
            count += 1;
        }
    }
    return result;
}



with entry {
    print(convert_to_dictionary('hello'));
}
