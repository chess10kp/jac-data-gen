"""Returns the number of gates to fold to achieve the desired (approximate)
    stretch factor.

    Args:
        stretch: Floating point value to stretch the circuit by.
        ngates: Number of gates in the circuit to stretch.
    """
def _get_num_to_fold(stretch: float, ngates: int) -> int {
    return int(round(((ngates * (stretch - 1.0)) / 2.0)));
}

test "t0" {
    assert (_get_num_to_fold(1.0, 1) == 0);;
}

test "t1" {
    assert (_get_num_to_fold(3.5, 5) == 6);;
}

test "t2" {
    assert (_get_num_to_fold(3.0, 5) == 5);;
}

test "t3" {
    assert (_get_num_to_fold(1.5, 2) == 0);;
}

test "t4" {
    assert (_get_num_to_fold(2.0, 3) == 2);;
}

test "t5" {
    assert (_get_num_to_fold(1.0, 5) == 0);;
}

test "t6" {
    assert (_get_num_to_fold(2.0, 1000) == 500);;
}

test "t7" {
    assert (_get_num_to_fold(2.0, 100) == 50);;
}

test "t8" {
    assert (_get_num_to_fold(1.1, 10) == 1);;
}

test "t9" {
    assert (_get_num_to_fold(1.4, 12) == 2);;
}

test "t10" {
    assert (_get_num_to_fold(1.6, 12) == 4);;
}

test "t11" {
    assert (_get_num_to_fold(1.0, 100) == 0);;
}
