"""
    converts every special character into a separate token
    """
def clean_word(word: str) -> list[str] {
    cleaned_words = [];
    temp = "";
    for char in word {
        if (33 <= ord(char) <= 47) or (58 <= ord(char) <= 64) {
            if temp != "" {
                cleaned_words.append(temp);
                temp = "";
            }
            cleaned_words.append(char);
        } else {
            temp += str(char);
        }
    }
    if temp != "" {
        cleaned_words.append(temp);
    }
    return cleaned_words;
}