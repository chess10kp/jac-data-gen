"""Remove parenthesis and trailing content from a character name string."""
def stripExtra(name: str) -> str {
    start_index = name.find('(');
    if start_index == -1 or start_index == 0 {
        return name;
    }
    return name[0:(start_index - 1)];
}