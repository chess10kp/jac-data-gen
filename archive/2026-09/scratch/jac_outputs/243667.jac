""" function to truncate anything over a certain number of characters.
    pretty much stolen from:
    http://stackoverflow.com/questions/250357/smart-truncate-in-python
    """
def smart_truncate(content: str, length: int = 100, suffix: str = '...') -> str {
    if not content or len(content) <= length {
        return content;
    }
    return ' '.join(content[:(length + 1)].split(' ')[0:-1]) + suffix;
}