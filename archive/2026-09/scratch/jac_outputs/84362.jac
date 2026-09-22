"""Description."""
def shorten_file_name(name: str) -> str {
    max_length = 60;
    if len(name) > max_length {
        return name[0:max_length] + "...";
    }
    return name;
}