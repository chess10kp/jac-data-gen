def convert_string_to_word_list(s: Any) -> object {
    if not s {
        return [];
    }
    words = re.findall(r"\w+(?:'\w+)?", s);
    sorted_words = sorted(words);
    return sorted_words;
}



with entry {
    print(convert_string_to_word_list(0));
}
