"""
    Helper function to check if a character is a valid URL character.
    """
def is_valid_url_char(char: Any) -> object {
    return (char.isalnum() or (char in ['-', '.', '_', '~']));
}



with entry {
    print(is_valid_url_char('hello'));
    print(is_valid_url_char('Hello, World!'));
}
