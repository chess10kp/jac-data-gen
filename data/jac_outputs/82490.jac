"""Returns the proper representation for a pin."""
def _pin_name(pin: str) -> int | str | None {
    pin = pin.strip();
    if not pin {
        return None;
    } elif pin.isdigit() {
        return int(pin);
    } elif pin == 'NO_PIN' {
        return None;
    } elif pin[0] in 'ABCDEFGHIJK' and pin[1].isdigit() {
        return pin;
    }
    raise ValueError(f'Invalid pin: {pin}');
}