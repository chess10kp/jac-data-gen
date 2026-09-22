"""
    Convert a string provided in camelCase to PascalCase
    """
def _convert_camel_to_pascal(camel_case_string: str) -> str {
    camel_case_string[:1].upper() + camel_case_string[1:]
}