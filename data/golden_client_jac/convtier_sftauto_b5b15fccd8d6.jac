def get_character(astring: Any) -> object {
    astring = astring.strip();
    astring = ''.join(
        char
        for char in astring
        if char.isalpha()
    );
    if (len(astring) > 4) {
        return astring[4];
    } else {
        return "String length is not greater than 4";
    }
}



with entry {
    print(get_character('hello'));
    print(get_character('Racecar'));
    print(get_character('abcabc'));
}
