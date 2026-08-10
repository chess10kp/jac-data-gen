"""Return sanitized access-point name: lowercase, max 50 chars, no invalid chars."""
def sanitize_ap_name(input_name: str) -> str {
    output_name = input_name.translate(str.maketrans({'_': '', '.': ''}));
    if output_name.startswith('-') {
        output_name = output_name[1:];
    }
    if output_name.endswith('-') {
        output_name = output_name[0:-1];
    }
    return output_name[0:50].lower();
}