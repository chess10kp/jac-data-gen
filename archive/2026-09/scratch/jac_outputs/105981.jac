"""Prefix names starting with a digit with 'a' for I3 map compatibility."""
def check_and_fix_names_starting_with_numbers(name: str) -> str {
    if name[0].isdigit() {
        return "a" + name;
    }
    return name;
}