def str2num(s):
    """User input is always received as string, str2num will try to cast it to the right type (int or float)"""

    try:
        return int(s)
    except ValueError:
        pass

    try:
        return float(s)
    except ValueError:
        # Fallback to the original type
        return s

assert str2num("three") == "three"
assert str2num('0.0') == 0.0
assert str2num('3.0') == 3.0
assert str2num(str(1)) == 1
assert str2num('3') == 3
assert str2num("123.45") == 123.45
assert str2num('1+2') == '1+2'
assert str2num("5.0") == 5.0
assert str2num("1.0e-3") == 0.001
assert str2num("1000.0") == 1000.0
assert str2num("3") == 3
assert str2num(" ") == " "
assert str2num("1.a") == "1.a"
assert str2num("42") == 42
assert str2num("42.0") == 42
assert str2num('123') == 123
assert str2num("42.") == 42.0
assert str2num("1.0") == 1.0
assert str2num("3.0") == 3.0
assert str2num(str2num(1)) == str2num(1)
assert str2num("a1.0e-3") == "a1.0e-3"
assert str2num('123abc') == '123abc'
assert str2num("a3") == "a3"
assert str2num("a1") == "a1"
assert str2num("42.0000") == 42.0
assert str2num(str2num(1.2)) == str2num(1.2)
assert str2num('1.1') == 1.1
assert str2num("  ") == "  "
assert str2num(1.) == 1.
assert str2num(str2num("1")) == str2num("1")
assert str2num("") == ""
assert str2num('1') == 1
assert str2num(-1.0) == -1.0
assert str2num("1.0000") == 1.0
assert str2num("2") == 2
assert str2num("-1.0") == -1.0
assert str2num(1000.0) == 1000.0
assert str2num("1") == 1
assert str2num(10) == 10
assert str2num(0) == 0
assert str2num("3a") == "3a"
assert str2num(str(1)) == int(str(1))
assert str2num(3.0) == 3.0
assert str2num("-1") == -1
assert str2num(5) == 5
assert str2num("1a") == "1a"
assert str2num('123.456') == 123.456
assert str2num("a3a") == "a3a"
assert str2num(0.0) == 0.0
assert str2num(1000) == 1000
assert str2num("3.4") == 3.4
assert str2num("a1.0") == "a1.0"
assert str2num("0") == 0
assert str2num('1.2') == 1.2
assert str2num('1.0') == 1.0
assert str2num(123) == 123
assert str2num(3) == 3
assert str2num("none") == "none"
assert str2num(1) == 1
assert str2num("1000") == 1000
assert str2num("5.5") == 5.5
assert str2num("-1.123456789012345678901234567890") == -1.123456789012345678901234567890
assert str2num("123a") == "123a"
assert str2num(1.0) == 1.0
assert str2num("1.123456789012345678901234567890") == 1.123456789012345678901234567890
assert str2num("None") == "None"
assert str2num("5") == 5
assert str2num("5a") == "5a"
assert str2num("one") == "one"
assert str2num("1.0e-3a") == "1.0e-3a"
assert str2num('x=1+2+3; print(x)') == 'x=1+2+3; print(x)'
assert str2num('12a') == '12a'
assert str2num('a') == 'a'
assert str2num("42.000") == 42.0
assert str2num("abc") == "abc"
assert str2num("1.2") == 1.2
assert str2num("3.5") == 3.5
assert str2num("1.a2") == "1.a2"
assert str2num("42.0") == 42.0
assert str2num('1+2+3') == '1+2+3'
assert str2num('1.') == 1.
assert str2num("-1.0e-3") == -0.001
assert str2num('0') == 0
assert str2num("1.5") == 1.5
assert str2num(-1) == -1
