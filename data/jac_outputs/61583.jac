"""Returns a new string with the first letter as lowercase."""
def first_letter_lower(input_string: str) -> str {
    input_string[:1].lower() + input_string[1:]
}