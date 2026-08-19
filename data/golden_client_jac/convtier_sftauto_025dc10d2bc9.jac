def count_unique_consonants(string: Any) -> object {
    consonants = `set();
    lowercase_string = string.lower();
    for char in lowercase_string {
        if (char.isalpha() and (char not in 'aeiou')) {
            consonants.add(char);
        }
    }
    return len(consonants);
}



with entry {
    print(count_unique_consonants('hello'));
    print(count_unique_consonants('Hello, World!'));
    print(count_unique_consonants('step on no pets'));
}
