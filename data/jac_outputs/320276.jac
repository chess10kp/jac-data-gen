"""
    Function to cut the passed in string before \n\n if any
    """
def process_description(description: str) -> str {
    if not description {
        return "No Info Provided";
    }
    return description.rpartition('\n\n')[0] if "\n\n" in description else description;
}