"""Split string by upper case letters and return capitalized words spaced."""
def camel_case_to_capitalized_spaced(string: str) -> str {
    words: list[str] = [];
    from_char_position = 0;
    for (current_char_position, char) in enumerate(string) {
        if char.isupper() and from_char_position < current_char_position {
            words.append(string[from_char_position:current_char_position].lower());
            from_char_position = current_char_position;
        }
    }
    words.append(string[from_char_position:].lower());
    capitalized_words = [word.upper()[0] + word.lower()[1:] for word in words];
    return ' '.join(capitalized_words);
}