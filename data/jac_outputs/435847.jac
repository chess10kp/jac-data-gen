"""Extract root value from display name
e.g. function(my_function) => my_function
"""
def info_to_name(display: str) -> str {
    try {
        return display.split('(')[1].rstrip(')');
    } except IndexError {
        return '';
    }
}