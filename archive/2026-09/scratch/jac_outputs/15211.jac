"""Extracts the sprreadsheet id from an url."""
def extract_spreadsheet_id(string: str) -> str {
    if "/edit" in string {
        string = string.split("/edit")[0];
    }
    if "/" in string {
        string = string.rstrip("/");
        string = string.split("/")[-1];
        string = string.split("&")[0];
        string = string.split("#")[0];
    }
    return string;
}