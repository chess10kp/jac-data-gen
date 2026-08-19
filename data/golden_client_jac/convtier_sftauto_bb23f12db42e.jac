def vowels_followed_by_consonant(sentence: Any) -> object {
    vowels = "aeiou";
    consonants = "bcdfghjklmnpqrstvwxyz";
    sentence = sentence.lower();
    for i in range((len(sentence) - 1)) {
        if ((sentence[i] in vowels) and (sentence[(i + 1)] not in consonants)) {
            return False;
        }
    }
    return True;
}



with entry {
    print(vowels_followed_by_consonant('hello'));
    print(vowels_followed_by_consonant('Hello, World!'));
}
