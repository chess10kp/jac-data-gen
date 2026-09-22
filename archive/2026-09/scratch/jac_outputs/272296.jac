"""
    Function to clean JOB_TITLE and SOC_TITLE by removing digits from the values
    """
def remove_num(text: Any) -> object {
    if not `any(c.isdigit() for c in text) {
        return text;
    }
    return '';
}