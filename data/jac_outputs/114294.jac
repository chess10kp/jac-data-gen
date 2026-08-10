"""
    Color a string for terminal output
    @params
        str - Required : the string to color
        color - Optional : the color to use. Default value: red. Available options: red, yellow, blue
    """
def colored(str: str, color: str = "red") -> str {
    colors = {
        "red": "\033[91m",
        "yellow": "\33[33m",
        "blue": "\33[34m",
        "green": "\33[32m"
    };
    end = "\033[0m";
    return f"{colors[color]}{str}{end}";
}