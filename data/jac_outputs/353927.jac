"""Add the "?" if absent"""
def _sparql_var(_input: str) -> str {
    _input if _input.startswith('?') else '?' + _input
}