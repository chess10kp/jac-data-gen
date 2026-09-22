"""To edit the text color."""
def color_text(c: str, txt: str) -> str | None {
    match c {
        case 'red':
            return '\033[91m{}\033[m'.format(txt);
        case 'white':
            return '\033[97m{}\033[m'.format(txt);
        case 'green':
            return '\033[92m{}\033[m'.format(txt);
        case 'yellow':
            return '\033[93m{}\033[m'.format(txt);
        case 'blue':
            return '\033[94m{}\033[m'.format(txt);
        case 'cyan':
            return '\033[96m{}\033[m'.format(txt);
        case 'magenta':
            return '\033[95m{}\033[m'.format(txt);
    }
}