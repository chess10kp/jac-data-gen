"""Transforma una string con elementos separados por `sep` en una lista."""
def string_to_list(string: str, sep: str = ",") -> list[str] {
    return [value.strip() for value in string.split(sep)];
}