"""Courtesy of http://stackoverflow.com/questions/1549641/how-to-capitalize-the-first-letter-of-each-word-in-a-string-python"""
def capitalize(line: str) -> str {
    return ' '.join(s[0].upper() + s[1:] for s in line.split(' '));
}