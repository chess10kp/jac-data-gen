"""Converts file path to file name."""
def get_file_name(path: str) -> str {
    parts = path.split("\\");
    file_name = parts[len(parts) - 1];
    file_name = file_name[:-len(".txt")];
    file_name = file_name.title();
    file_name += " file";
    return file_name;
}