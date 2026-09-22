""" Receive string and print it"""
def pythoniscool(text: str = "is cool") -> str {
    text = text.replace('_', ' ');
    return 'Python %s' % text;
}