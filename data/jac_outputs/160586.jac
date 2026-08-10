"""e.g., sort 'INT8' before 'INT16'"""
def sort_key(string: str) -> str {
    return string.replace("8", "08");
}