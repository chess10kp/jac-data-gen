def to_real(real, x):
    """
    Helper function to convert a value x to a type real.
    This exists because not every type has a direct conversion,
    but maybe we can help it?
    """
    try:
        # the obvious way
        return real(x)
    except TypeError as exc:
        # well seems like that won't work
        # let's see what types we can help it with
        if hasattr(x, 'denominator'):
            # ah, it's a fraction!
            return to_real(real, x.numerator) / to_real(real, x.denominator)
        # welp, we failed
        raise exc

assert to_real(float, 100) == 100.0
assert to_real(float, 0) == 0.0
assert to_real(complex, 1) == 1
assert to_real(int, 1) == 1
assert to_real(float, 100.0) == 100.0
assert to_real(float, 1/3.0) == 0.3333333333333333
assert to_real(float, 3.14) == 3.14
assert to_real(float, -1e200) == -1e200
assert to_real(float, 1e100) == 1e100
assert to_real(float, 3.1415926) == 3.1415926
assert to_real(lambda x: x, 3.0) == 3.0
assert to_real(complex, 2j) == 2j
assert to_real(float, 5) == 5.0
assert to_real(float, 3.141592653589793) == 3.141592653589793
assert to_real(complex, 1.0) == 1
assert to_real(int, 0) == 0
assert to_real(int, 100.0) == 100
assert to_real(complex, 1j) == 1j
assert to_real(complex, complex(1)) == 1
assert to_real(complex, 100.0) == 100+0j
assert to_real(int, 1/2) == 0
assert to_real(complex, 100.5) == 100.5+0j
assert to_real(float, 100.5) == 100.5
assert to_real(int, 2) == 2
assert to_real(int, 2.0) == 2
assert to_real(float, 1.5) == 1.5
assert to_real(lambda x: x, 3) == 3
assert to_real(int, 5) == 5
assert to_real(int, 3.1415926) == 3
assert to_real(float, 1e-200) == 1e-200
assert to_real(int, 2.71828) == 2
assert to_real(int, 100.5) == 100
assert to_real(float, 2.71828) == 2.71828
assert to_real(int, 1.5) == 1
assert to_real(float, 3) == 3.0
assert to_real(float, -5) == -5.0
assert to_real(float, 1.0) == 1.0
assert to_real(int, 1.1) == 1
assert to_real(float, 2) == 2.0
assert to_real(int, 100) == 100
assert to_real(complex, 100) == 100+0j
assert to_real(float, -1e100) == -1e100
assert to_real(float, 2.3) == 2.3
assert to_real(float, 1) == 1.0
assert to_real(float, 1 / 2) == 0.5
assert to_real(float, 42) == 42.0
assert to_real(float, 0.5) == 0.5
assert to_real(float, 3.0) == 3.0
assert to_real(float, 1/2) == 0.5
assert to_real(int, 3.0) == 3
assert to_real(int, 42) == 42
assert to_real(int, 1.0) == 1
assert to_real(float, 1/3) == 0.3333333333333333
assert to_real(float, 5.0) == 5.0
assert to_real(float, -1e-200) == -1e-200
assert to_real(int, 3) == 3
assert to_real(int, 5.0) == 5
assert to_real(float, 1e200) == 1e200
