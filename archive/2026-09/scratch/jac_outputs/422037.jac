"""Recibe bytes y los convierte a entero."""
def read_int32(val: bytes) -> int {
    return int.from_bytes(val, "little");
}