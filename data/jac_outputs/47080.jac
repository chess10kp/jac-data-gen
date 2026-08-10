"""Return colored string."""
def color_text(color_enabled: bool, color: str, string: str) -> str {
    if color_enabled {
        return '\n'.join(
            '\033[' + color + 'm' + s + '\033[0m' if s else ''
            for s in string.split('\n')
        );
    }
    return string;
}