"""Converts snake_case strings to CameCase"""
def consistentCase(name: str) -> str {
    return ''.join([word[0].upper() + word[1:] for word in name.split('_')]);
}