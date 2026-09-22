"""
Ensures that the name of object used to create paths in file system do not
contain characters that would be handled erroneously (e.g. \ or / that
normally separate file directories).
"""
def correct_name(name: str) -> str {
    corrected_name = name.replace(" ", "_");
    corrected_name = corrected_name.replace("\\", "_");
    corrected_name = corrected_name.replace("/", "_");
    corrected_name = corrected_name.replace(":", "_");
    return corrected_name;
}