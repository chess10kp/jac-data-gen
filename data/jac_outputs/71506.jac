"""Get the year from the datestr part of a file."""
def get_year_filename(file: Any) -> object {
    date_parts = [int(d) for d in file.split('.')[-2].split('-')];
    return date_parts[0];
}