def get_first_consonants(string: Any) -> object {
    result = "";
    words = string.split();
    for word in words {
        consonants = "";
        for char in word {
            if ((char.lower() not in "aeiou") and not char.isdigit()) {
                consonants += char.lower();
                break;
            }
        }
        result += consonants;
    }
    return result;
}



with entry {
    print(get_first_consonants('hello'));
    print(get_first_consonants('Racecar'));
    print(get_first_consonants('abcabc'));
}
