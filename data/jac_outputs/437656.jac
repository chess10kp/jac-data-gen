""" Remove duplicate spaces from str and strip it. """
def clean_text_up(text: str) -> str {
    ' '.join(text.split()).strip()
}