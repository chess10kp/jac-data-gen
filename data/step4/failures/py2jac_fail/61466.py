def cross(a: complex, b: complex) -> complex:
    """2D cross product (a.k.a. wedge product) of two vectors.

    Args:
        a (complex): First vector.
        b (complex): Second vector.

    Returns:
        complex: 2D cross product: a.x * b.y - a.y * b.x
    """
    return (a.conjugate() * b).imag

assert cross(0j, 1 + 0j) == 0j
assert cross(6, 6) == 0
assert cross(-1, 0) == 0
assert cross(1 + 2j, 1 + 2j) == 0
assert cross(1 + 1j, 1 - 1j) == -2
assert cross(2j, -2j) == 0j
assert cross(4, 4) == 0
assert cross(1 + 1j, 0) == 0
assert cross(10, 10) == 0
assert cross(complex(1, 0), complex(1, 0)) == 0
assert cross(1, 2) == 0
assert cross(1 + 1j, -1 + 1j) == 2
assert cross(2j, 2j) == 0
assert cross(1j, 0) == 0
assert cross(0, 0) == 0
assert cross(1 - 1j, 1 - 1j) == -0j
assert cross(1 + 1j + 1j, 1 + 1j + 1j) == 0
assert cross(2 + 2j, 2 + 2j) == 0
assert cross(1 - 1j, 1 + 1j) == 2
assert cross(1j, -1j) == 0j
assert cross(0.0+1.0j, 0.0+1.0j) == 0.0+0.0j
assert cross(0, -3) == 0
assert cross(7, 7) == 0
assert cross(3 + 4j, 3 + 4j) == 0
assert cross(1 - 1j, 1 - 1j) == 0
assert cross(-1, 1) == 0
assert cross(1 + 1j, 1j) == 1
assert cross(complex(1, 2), complex(3, 4)) == cross(1 + 2j, 3 + 4j)
assert cross(1 + 1j, -1 - 1j) == 0
assert cross(0, 1j) == 0
assert cross(1, -1) == 0
assert cross(1j, -1 + 0j) == 1
assert cross(1j, 1j) == 0
assert cross(2 + 1j, 2 + 1j) == 0
assert cross(0 + 1j, 0 + 1j) == 0
assert cross(2j, 2j) == 0j
assert cross(3 - 4j, 3 - 4j) == 0
assert cross(1 + 2j, 3 + 4j) == 1 * 4 - 2 * 3
assert cross(-1 + 1j, -1 + 1j) == 0
assert cross(0j, 0j) == 0j
assert cross(9, 9) == 0
assert cross(-1 + 1j, 1 + 1j) == -2
assert cross(1+2j, 2+3j) == -1
assert cross(8, 8) == 0
assert cross(-1j, -1 + 0j) == -1
assert cross(1j, 1 + 0j) == -1
assert cross(1, 1) == 0
assert cross(1 + 1j, 1 + 1j) == 0
assert cross(1j, 1j) == 0j
assert cross(complex(1, 2), complex(3, 4)) == cross(complex(1, 2), 3 + 4j)
assert cross(1j, 1 + 1j) == -1
assert cross(-1j, 1 + 0j) == 1
assert cross(1, 1j) == 1
assert cross(0, -1) == 0
assert cross(3, 3) == 0
assert cross(1, 0) == 0.0
assert cross(3 + 4j, 1 + 2j) == -1 * 4 + 2 * 3
assert cross(-1j, -1j) == 0
assert cross(1 + 0j, 0j) == 0j
assert cross(0.0+0.0j, 1.0+0.0j) == 0.0+0.0j
assert cross(5, 5) == 0
assert cross(-1, -1) == 0
assert cross(complex(1, 1), complex(1, 1)) == 0
assert cross(2, 2) == 0
assert cross(1, 0) == 0
assert cross(0, 1) == 0
assert cross(1j, -1j) == 0
assert cross(1 + 0j, 1 + 0j) == 0
assert cross(0, 1) == 0.0
assert cross(0, 0) == 0.0
