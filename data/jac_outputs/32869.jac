"""
    Titleizes a string, aka transforms it from underscored to English title
    format
    """
def titleize(s: str) -> str {
    s = s.replace('_', ' ');
    words = s.split(' ');
    return ' '.join(w[0].upper() + w[1:] for w in words);
}