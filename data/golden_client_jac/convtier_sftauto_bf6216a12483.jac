def is_palindrome(sentence: Any) -> object {
    sentence = sentence.replace(" ", "").replace(",", "").replace(".", "").replace(
        "!", ""
    ).replace(
        "?", ""
    ).replace(
        "'", ""
    ).replace(
        "\"", ""
    ).replace(
        ":", ""
    ).replace(
        ";", ""
    );
    sentence = sentence.lower();
    if (sentence == sentence[::-1]) {
        return True;
    } else {
        return False;
    }
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
