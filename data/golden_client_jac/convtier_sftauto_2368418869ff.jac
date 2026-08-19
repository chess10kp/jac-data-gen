def convert_to_dictionary(string_list: Any) -> object {
    result = {};
    count = 1;
    for string in string_list {
        uppercase_string = string.upper();
        if (
            (len(uppercase_string) >= 8)
            and (len(`set(uppercase_string)) == len(uppercase_string))
            and (uppercase_string[::-1] != uppercase_string)
        ) {
            vowels_count = 0;
            for char in uppercase_string {
                if (char in "AEIOU") {
                    vowels_count += 1;
                }
            }
            if (vowels_count >= 3) {
                result[count] = uppercase_string;
                count += 1;
            }
        }
    }
    return result;
}



with entry {
    print(convert_to_dictionary('hello'));
}
