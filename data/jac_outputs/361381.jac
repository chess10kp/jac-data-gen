"""(string) -> string
proprely capitalize course titles"""
def helper_capitalize(text: str) -> str {
    return ''.join(char.upper() if char.isalpha() else char for char in text);
}