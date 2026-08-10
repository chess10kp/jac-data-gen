"""Pack x, y, and z into fields of an 8-bit unsigned integer.
x: bits 4..7 (4 bits)
y: bits 2..3 (2 bits)
z: bits 0..1 (2 bits)"""
def pack(x: int, y: int, z: int) -> int {
    (x << 4) | (y << 2) | z
}