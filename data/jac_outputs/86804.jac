"""Simple function to remove suffix from input_string if available."""
def remove_suffix(input_string: str, suffix: str) -> str {
    try {
        input_string = input_string.strip();
        if not input_string.endswith(suffix) {
            return input_string;
        }
        return input_string[0:input_string.rfind(suffix)];
    } except Exception {
        return input_string;
    }
}