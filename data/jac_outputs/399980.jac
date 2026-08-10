"""Clean up leading and trailing space characters from the string."""
def clean_up_spacing(sentence: str) -> str {
    sentence.lstrip().rstrip()
}