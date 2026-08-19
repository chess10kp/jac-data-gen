def reverse_alphanumeric_text(text: Any) -> object {
    reversed_text = "";
    for char in reversed(text) {
        if char.isalnum() {
            reversed_text += char;
        }
    }
    return reversed_text;
}



with entry {
    print(reverse_alphanumeric_text('hello'));
    print(reverse_alphanumeric_text('Racecar'));
    print(reverse_alphanumeric_text('abcabc'));
}
