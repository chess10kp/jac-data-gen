def isVowel(char: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    return (char.lower() in vowels);
}



with entry {
    print(isVowel('hello'));
}
