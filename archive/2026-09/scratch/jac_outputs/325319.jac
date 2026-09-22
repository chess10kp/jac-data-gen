"""Returns True if the input data appears to be a X12 message."""
def is_x12_data(input_data: str) -> bool {
    return input_data.startswith("ISA") if input_data else False;
}