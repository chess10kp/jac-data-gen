"""
    Converts a list of cpu cores in corresponding hex value
    of cpu-mask
    """
def comma_list_to_hex(cpus: str) -> str {
    binary_mask = 0;
    for cpu in cpus.split(",") {
        binary_mask = binary_mask | (1 << int(cpu));
    }
    return format(binary_mask, '02x');
}