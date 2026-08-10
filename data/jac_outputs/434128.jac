""" "O1" -> "O" """
def remove_digits(name: str) -> str {
    ''.join(i for i in name if not i.isdigit())
}