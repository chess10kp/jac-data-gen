"""Sanitizes and removes all useless characters from the text, returns sanitized text string"""
def sanitize_text(text: str) -> str {
    alphanum_text = "";
    for letter in list(text) {
        if letter.isalnum() or letter == " " or letter in "!?.,:;\'\"&()$%#@~" {
            alphanum_text += letter;
        }
    }
    return alphanum_text;
}