def convert_to_pig_latin(word: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    if (word.lower() == word.lower()[::-1]) {
        return (word[::-1] + 'ay');
    } elif (word.lower()[0] in vowels) {
        return (word + 'way');
    } else {
        return (word[1:] + word[0] + 'ay');
    }
}



with entry {
    print(convert_to_pig_latin('hello'));
    print(convert_to_pig_latin('Racecar'));
    print(convert_to_pig_latin('abcabc'));
}
