"""Returns the memory value in GB from a given string in kB."""
def get_memory_in_GB(memory_str: str) -> str {
    try {
        return '{0} GB'.format(int(memory_str[:-2]) / 1000000);
    } except (ValueError, TypeError) {
        return '';
    }
}