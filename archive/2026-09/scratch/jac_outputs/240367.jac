"""Restore symbol for XueQiu."""
def symbol_restore(symbol: str) -> str {
    return f'{symbol[2:]}.{symbol[:2]}';
}