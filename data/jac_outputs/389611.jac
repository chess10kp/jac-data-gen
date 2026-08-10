"""Converts a csv filename string to its matching json filename."""
def csv_to_json(csv_filename: str) -> str {
    csv_trimmed = csv_filename[:-3];
    json_added = csv_trimmed + 'json';
    return json_added;
}