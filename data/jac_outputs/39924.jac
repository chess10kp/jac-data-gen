"""
    Returns a str of a section header for the asm file.
    """
def dump_section(bank_number: Any, separator: Any = "\n\n") -> object {
    output = "SECTION \"";
    if (bank_number in [0, "0"]) {
        output += "bank0\",HOME";
    } else {
        output += "bank";
        output += bank_number;
        output += "\",DATA,BANK[$";
        output += bank_number;
        output += "]";
    }
    output += separator;
    return output;
}