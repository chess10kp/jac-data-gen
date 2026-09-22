def str_to_nat(s):
    """Convert string to natural number."""
    return ord(s) - ord("a")

assert str_to_nat(chr(107)) == 10
assert str_to_nat("k") == 10
assert str_to_nat(chr(109)) == 12
assert str_to_nat(chr(112)) == 15
assert str_to_nat(chr(103)) == 6
assert str_to_nat(chr(ord("a") + 4)) == 4
assert str_to_nat(chr(118)) == 21
assert str_to_nat("") == 20
assert str_to_nat("i") == 8
assert str_to_nat("h") == 7
assert str_to_nat("s") == 18
assert str_to_nat("z") == 25
assert str_to_nat("q") == 16
assert str_to_nat(chr(ord("a") + 0)) == 0
assert str_to_nat(chr(ord("a") + 15)) == 15
assert str_to_nat("z") == 25
assert str_to_nat(chr(110)) == 13
assert str_to_nat(chr(ord("a") + 7)) == 7
assert str_to_nat("m") == 12
assert str_to_nat(chr(ord("a") + 14)) == 14
assert str_to_nat(chr(106)) == 9
assert str_to_nat("n") == 13
assert str_to_nat(chr(ord("a") + 1)) == 1
assert str_to_nat("l") == 11
assert str_to_nat(chr(105)) == 8
assert str_to_nat(chr(ord("a") + 2)) == 2
assert str_to_nat(chr(111)) == 14
assert str_to_nat(chr(100)) == 3
assert str_to_nat("b") == 1
assert str_to_nat(chr(116)) == 19
assert str_to_nat("v") == 21
assert str_to_nat(chr(ord("a") + 16)) == 16
assert str_to_nat(chr(114)) == 17
assert str_to_nat(chr(102)) == 5
assert str_to_nat(chr(99)) == 2
assert str_to_nat("g") == 6
assert str_to_nat(chr(ord("a") + 10)) == 10
assert str_to_nat(chr(ord("a") + 8)) == 8
assert str_to_nat(chr(ord("a") + 6)) == 6
assert str_to_nat("p") == 15
assert str_to_nat(chr(ord("a") + 11)) == 11
assert str_to_nat(chr(104)) == 7
assert str_to_nat( "a" ) == 0
assert str_to_nat("r") == 17
assert str_to_nat("e") == 4
assert str_to_nat("j") == 9
assert str_to_nat(chr(ord("a") + 17)) == 17
assert str_to_nat("t") == 19
assert str_to_nat(chr(98)) == 1
assert str_to_nat("b") == 1
assert str_to_nat("a") == 0
assert str_to_nat("o") == 14
assert str_to_nat(chr(113)) == 16
assert str_to_nat(chr(119)) == 22
assert str_to_nat(chr(115)) == 18
assert str_to_nat(chr(ord("a") + 13)) == 13
assert str_to_nat("y") == 24
assert str_to_nat("w") == 22
assert str_to_nat("d") == 3
assert str_to_nat("x") == 23
assert str_to_nat("f") == 5
assert str_to_nat(chr(ord("a") + 3)) == 3
assert str_to_nat(chr(101)) == 4
assert str_to_nat(chr(97)) == 0
assert str_to_nat(chr(ord("a") + 5)) == 5
assert str_to_nat(chr(ord("a") + 9)) == 9
assert str_to_nat(chr(117)) == 20
assert str_to_nat( "z" ) == 25
assert str_to_nat(chr(ord("a") + 12)) == 12
assert str_to_nat("a") == 0
assert str_to_nat( "c" ) == 2
assert str_to_nat("c") == 2
assert str_to_nat(chr(108)) == 11
