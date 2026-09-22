"""Converts a string from a MixedCaseString to a UPPER_SNAKE_CASE_STRING."""
def to_upper_snake_case(s: str) -> str {
    ''.join(c if c.isalnum() else '_' for c in s.upper())
}