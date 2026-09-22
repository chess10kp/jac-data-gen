import re;

"""Converts carets to exponent symbol in string"""
def fix_carets(expr: str) -> str {
    caret = re.compile(r'[\^]');
    return caret.sub('**', expr);
}