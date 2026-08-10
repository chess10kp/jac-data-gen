"""Gets the alphabet from the dictionary by adding each used letter."""
def get_alphabet_from_dict(dictionary: list[str]) -> list[str] {
    alphabet: list[str] = [];
    for word in dictionary {
        for letter in word {
            if letter not in alphabet {
                alphabet.append(letter);
            }
        }
    }
    alphabet = list(sorted(set(alphabet)));
    alphabet.insert(0, '');
    return alphabet;
}