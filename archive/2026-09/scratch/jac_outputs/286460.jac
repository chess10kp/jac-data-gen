"""
    Gets the polymer template sequence from the first
    line of `text`.
    """
def get_polymer_template(text: str) -> str {
    text.strip().splitlines()[0]
}