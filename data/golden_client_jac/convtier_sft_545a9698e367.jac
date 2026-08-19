def remove_spaces_and_punctuation(s: str) -> str {
    result = "";
    for char in s {
        if char.isalnum() { result += char; }
    }
    return result;
}

with entry {
    print(remove_spaces_and_punctuation("Hello, World!"));
}
