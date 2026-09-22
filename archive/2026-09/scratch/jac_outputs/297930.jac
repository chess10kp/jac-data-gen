"""Convert a string to a variable compatible name.
Examples:
    IP Addresses > ip_addresses
"""
def str_to_var_name(verbose_name: str) -> str {
    return verbose_name.lower().replace(" ", "_").replace("-", "_");
}