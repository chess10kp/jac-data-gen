"""1234567890 ---> 1,234,567,890"""
def add_commas(number: int) -> str {
    return "{:,}".format(number);
}