"""Split accession into prefix and number, uppercasing the type prefix."""
def split_accn(accn: str) -> tuple[str, str] {
    (typename, number_text) = (accn[:3], accn[3:]);
    return (typename.upper(), number_text);
}