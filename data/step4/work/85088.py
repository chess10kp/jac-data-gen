def _calc_resolelement(w, fcol, r, A):
    """Calculate the resolution element using dw=r*w/A/fcol

       returns resolution element in mm
    """
    return r * w / A / fcol

assert _calc_resolelement(1.0, 1.0, 1.0, 10.0) == 0.1
assert _calc_resolelement(0.5, 2, 4.0, 5) == 0.2
assert _calc_resolelement(2, 1, 1, 2) == 1
assert _calc_resolelement(1.0, 1.0, 1.0, 1.0) == 1.0
assert _calc_resolelement(1.0, 1.0, 1.0, 2.0) == 0.5
assert _calc_resolelement(10000, 10, 0, 10000) == 0.0
assert _calc_resolelement(2, 2, 1, 2) == 0.5
assert _calc_resolelement(2, 1, 1, 2) == 1.0
assert _calc_resolelement(1, 10, 100, 1) == 10
assert _calc_resolelement(1, 1.0, 1, 1.0) == 1.0
assert _calc_resolelement(10, 0.5, 0.1, 2) == 1
assert _calc_resolelement(2.0, 1.0, 1.0, 1.0) == 2.0
assert _calc_resolelement(1.0, 1, 1, 1) == 1.0
assert _calc_resolelement(1, 1, 1, 2) == 0.5
assert _calc_resolelement(1, 10, 1000, 10) == 10
assert _calc_resolelement(1, 10, 10, 1) == 1
assert _calc_resolelement(1, 2, 1, 1) == 0.5
assert _calc_resolelement(1.0, 1, 1, 1.0) == 1.0
assert _calc_resolelement(1, 1, 2, 1) == 2
assert _calc_resolelement(1, 1, 1, 1.0) == 1.0
assert _calc_resolelement(1, 1, 1, 1) == 1.0
assert _calc_resolelement(1, 1.0, 1, 1) == 1.0
assert _calc_resolelement(1, 1, 1, 1) == 1
assert _calc_resolelement(2, 2, 1, 1) == 1
