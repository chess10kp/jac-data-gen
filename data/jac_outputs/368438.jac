"""Extracts a message"""
def extract_msg(elem: str) -> str {
    if ' % ' in elem {
        elem = ''.join(elem.split(' % ')[:-1]);
    }
    return elem.rstrip(')').strip('"').strip("'");
}