"""Return label definition text at a given address.

Format: '{label}: ; {address}'"""
def generate_label_asm(label: str, address: int) -> tuple[int, str, int] {
    label_text = '%s: ; %x' % (label, address);
    return (address, label_text, address);
}