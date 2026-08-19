def int2str(integer):
    """Representation of an integer as character"""
    if integer < 26:
        return chr(integer + ord('a'))
    elif integer < 52:
        return chr(integer - 26 + ord('A'))
    elif integer < 62:
        return chr(integer - 52 + ord('0'))
    else:
        raise ValueError("Invalid integer, can't convert")

assert int2str(8) == 'i'
assert int2str(9) == 'j'
assert int2str(0) == chr(0x61)
assert int2str(1) == 'b'
assert int2str(5) == 'f'
assert int2str(20) == ''
assert int2str(25) == "z"
assert int2str(18) =='s'
assert int2str(30) == 'E'
assert int2str(21) == 'v'
assert int2str(13) == 'n'
assert int2str(11) == 'l'
assert int2str(0) == 'a'
assert int2str(15) == 'p'
assert int2str(6) == 'g'
assert int2str(23) == 'x'
assert int2str(7) == 'h'
assert int2str(12) =='m'
assert int2str(0) == "a"
assert int2str(29) == 'D'
assert int2str(1) == "b"
assert int2str(16) == 'q'
assert int2str(24) == 'y'
assert int2str(26) == 'A'
assert int2str(22) == 'w'
assert int2str(2) == 'c'
assert int2str(52) == '0'
assert int2str(17) == 'r'
assert int2str(27) == "B"
assert int2str(2) == "c"
assert int2str(25) == 'z'
assert int2str(28) == 'C'
assert int2str(52) == "0"
assert int2str(3) == 'd'
assert int2str(61) == '9'
assert int2str(31) == 'F'
assert int2str(27) == 'B'
assert int2str(61) == "9"
assert int2str(51) == 'Z'
assert int2str(26) == "A"
assert int2str(51) == "Z"
assert int2str(4) == 'e'
assert int2str(10) == 'k'
assert int2str(14) == 'o'
assert int2str(19) == 't'
