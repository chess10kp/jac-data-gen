"""Any subsequent byte is a continuation byte if the MSB is set."""
def is_continuation(val: int) -> bool {
    return val & 128 == 128;
}