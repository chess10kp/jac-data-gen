def reverse_array(arr: Any) -> object {
    vowels = [];
    consonants = [];
    for string in arr {
        if (string[0].lower() in ['a', 'e', 'i', 'o', 'u']) {
            vowels.append(string);
        } else {
            consonants.append(string);
        }
    }
    vowels.reverse();
    consonants.reverse();
    return (vowels + consonants);
}



with entry {
    print(reverse_array('hello'));
    print(reverse_array('Racecar'));
    print(reverse_array('abcabc'));
}
