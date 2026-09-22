"""defined here: http://nagiosplug.sourceforge.net/developer-guidelines.html#AEN201"""
def performance_data(
    label: str,
    value: str,
    uom: str = "",
    warn: str = "",
    crit: str = "",
    mini: str = "",
    maxi: str = ""
) -> str {
    formatted_string = f"{label}={value}{uom};{warn};{crit};{mini};{maxi}";
    formatted_string = "".join(formatted_string.split());
    return formatted_string;
}