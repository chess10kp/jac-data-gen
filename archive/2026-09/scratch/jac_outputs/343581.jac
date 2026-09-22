"""Format seconds as hours, minutes, and seconds."""
def format_seconds(seconds: float) -> str {
    minutes = int(seconds // 60);
    hours = int(minutes // 60);
    remainder_sec = seconds % 60;
    remainder_min = minutes % 60;
    output_str = "";
    if hours != 0 {
        output_str += f"{hours} h ";
    }
    if minutes != 0 {
        output_str += f"{remainder_min} min ";
    }
    output_str += f"{remainder_sec:.2f} s";
    return output_str;
}