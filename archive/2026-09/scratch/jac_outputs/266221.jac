"""Find a secret message"""
def find_message(text: str) -> str {
    import re;
    pattern = re.compile(r'[A-Z]');
    return ''.join(pattern.findall(text));
}