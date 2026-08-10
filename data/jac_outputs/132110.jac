import re;

"""commafy(number) - add commas to a number."""
def commafy(number: int | float) -> str {
    return re.sub(r'(\d{3})(?=\d)', r'\1,', str(number)[::-1])[::-1];
}