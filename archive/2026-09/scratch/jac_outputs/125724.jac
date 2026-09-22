"""Returns A String with the custom wordlist removed """
def remove_custom_words(text: Any, custom_wordlist: Any) -> object {
    result = [
        word
        for word in text.split()
        if (word.lower() not in custom_wordlist)
    ];
    return " ".join(result);
}