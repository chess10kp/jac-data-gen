def usub(x):
    """Implementation of `usub`."""
    return x.__neg__()

assert usub(-2.5) == 2.5
assert usub(usub(usub(usub(-1)))) == -1
assert usub(-1 - 2j) == 1 + 2j
assert usub(-4.92) == 4.92
assert usub(-1) == 1
assert usub(-4.0) == 4.0
assert usub(-1.0) == 1.0
assert usub(10.0) == -10.0
assert usub(-100.0) == 100.0
assert usub(20) == -20
assert usub(-1 + 2j) == 1 - 2j
assert usub(0.0) == -0.0
assert usub(complex(1, 2)) == complex(-1, -2)
assert usub(3.14) == -3.14
assert usub(-10) == 10
assert usub(usub(usub(usub(0.0)))) == 0.0
assert usub(-10j) == 10j
assert usub(-1.5) == 1.5
assert usub(usub(usub(2.5))) == -2.5
assert usub(usub(usub(1))) == -1
assert usub(1 + 2j) == -1 - 2j
assert usub(123456789) == -123456789
assert usub(usub(usub(0.0))) == 0.0
assert usub(4 + 3j) == -4 - 3j
assert usub(-1-1j) == 1+1j
assert usub(-10.0) == 10.0
assert usub(*[1]) == -1
assert usub(-3) == 3
assert usub(300) == -300
assert usub(usub(-2)) == -2
assert usub(5) == -5
assert usub(2000) == -2000
assert usub(3) == -3
assert usub(usub(usub(usub(1)))) == 1
assert usub(False) == 0
assert usub(3.0) == -3.0
assert usub(usub(0.0)) == 0.0
assert usub(5.0) == -5.0
assert usub(usub(-3)) == -3
assert usub(1 - 2j) == -1 + 2j
assert usub(0) == 0
assert usub(-1j) == 1j
assert usub(4.0) == -4.0
assert usub(usub(0)) == 0
assert usub(usub(-1)) == -1
assert usub(usub(2)) == 2
assert usub(1.2) == -1.2
assert usub(usub(1.2)) == 1.2
assert usub(-2 - 2j) == 2 + 2j
assert usub(-2) == 2
assert usub(1j) == -1j
assert usub(usub(3)) == 3
assert usub(2 - 2j) == -2 + 2j
assert usub(10.0 + 10.0j) == -10.0 - 10.0j
assert usub(usub(-1.2)) == -1.2
assert usub(10j) == -10j
assert usub(usub(1)) == 1
assert usub(-2 + 2j) == 2 - 2j
assert usub(1.0 + 1.0j) == -1.0 - 1.0j
assert usub(0.0001) == -0.0001
assert usub(1) == -1
assert usub(complex(3, 4)) == complex(-3, -4)
assert usub(-5) == 5
assert usub(usub(usub(usub(1.2)))) == 1.2
assert usub(True) == -1
assert usub(0.0 + 0.0j) == 0.0 + 0.0j
assert usub(2.5) == -2.5
assert usub(-100) == 100
assert usub(-1.23456) == 1.23456
assert usub(1.0) == -1.0
assert usub(-100.00000001) == 100.00000001
assert usub(-1.2) == 1.2
assert usub(6.4) == -6.4
assert usub(1.5) == -1.5
assert usub(-1+1j) == 1-1j
assert usub(usub(2.5)) == 2.5
assert usub(usub(usub(usub(0)))) == 0
assert usub(-7) == 7
assert usub(10) == -10
assert usub(usub(usub(-1.2))) == 1.2
assert usub(-4) == 4
assert usub(1.23456) == -1.23456
assert usub(2 + 2j) == -2 - 2j
assert usub(2) == -2
assert usub(6.0) == -6.0
assert usub(usub(usub(0))) == 0
assert usub(0.0) == 0.0
assert usub(30000) == -30000
assert usub(usub(usub(1.2))) == -1.2
assert usub(usub(usub(-1))) == 1
assert usub(-123456789) == 123456789
assert usub(-7.0) == 7.0
assert usub(4) == -4
