"""Replaces mongodb characters format with standard characters."""
def clean_chars_reverse(command: str) -> str {
    clean_freq_data = command;
    if "(Dot)" in clean_freq_data {
        clean_freq_data = clean_freq_data.replace("(Dot)", ".");
    }
    if "(Dollar_Sign)" in clean_freq_data {
        clean_freq_data = clean_freq_data.replace("(Dollar_Sign)", "$");
    }
    return clean_freq_data;
}