"""Converts text that may be underscored into a camelcase format"""
def camelcase_text(text: str) -> str {
    return text[0] + "".join(text.title().split('_'))[1:];
}