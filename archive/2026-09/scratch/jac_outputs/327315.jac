"""Return the cleaned-up file title."""
def clean_up_filename(file_name: str) -> str {
    return file_name.strip().replace(' ', '_');
}