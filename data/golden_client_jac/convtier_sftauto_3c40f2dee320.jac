def count_syllables(word: Any) -> object {
    vowels = 'aeiou';
    count = 0;
    for i in range(len(word)) {
        if (
            (word[i].lower() in vowels)
            and ((i == 0) or (word[(i - 1)].lower() not in vowels))
        ) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_syllables('hello'));
    print(count_syllables('Racecar'));
    print(count_syllables('step on no pets'));
}
