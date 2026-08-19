def capitalize_names(names: List[str]) -> List[str] {
    modified_names = [];
    for name in names {
        words = name.split(" ");
        capitalized_words = [];
        for word in words {
            capitalized_word = word.lower().capitalize();
            capitalized_words.append(capitalized_word);
        }
        modified_name = " ".join(capitalized_words);
        modified_names.append(modified_name);
    }
    return modified_names;
}



with entry {
    print(capitalize_names('hello'));
    print(capitalize_names('Racecar'));
    print(capitalize_names('abcabc'));
}
