"""Takes a string and removes multiple blank lines"""
def remove_multiple_blank_lines(instring: str) -> str {
    while '\n\n' in instring {
        instring = instring.replace('\n\n', '\n');
    }
    return instring.strip();
}