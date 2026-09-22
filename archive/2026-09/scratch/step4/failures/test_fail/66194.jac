"""Representation of an integer as character"""
def int2str(integer: Any) -> object {
    if (integer < 26) {
        return chr((integer + ord('a')));
    } elif (integer < 52) {
        return chr(((integer - 26) + ord('A')));
    } elif (integer < 62) {
        return chr(((integer - 52) + ord('0')));
    } else {
        raise ValueError("Invalid integer, can't convert");
    }
}

test "t0" {
    assert (int2str(8) == 'i');;
}

test "t1" {
    assert (int2str(9) == 'j');;
}

test "t2" {
    assert (int2str(0) == chr(97));;
}

test "t3" {
    assert (int2str(1) == 'b');;
}

test "t4" {
    assert (int2str(5) == 'f');;
}

test "t5" {
    assert (int2str(20) == '');;
}

test "t6" {
    assert (int2str(25) == "z");;
}

test "t7" {
    assert (int2str(18) == 's');;
}

test "t8" {
    assert (int2str(30) == 'E');;
}

test "t9" {
    assert (int2str(21) == 'v');;
}

test "t10" {
    assert (int2str(13) == 'n');;
}

test "t11" {
    assert (int2str(11) == 'l');;
}

test "t12" {
    assert (int2str(0) == 'a');;
}

test "t13" {
    assert (int2str(15) == 'p');;
}

test "t14" {
    assert (int2str(6) == 'g');;
}

test "t15" {
    assert (int2str(23) == 'x');;
}

test "t16" {
    assert (int2str(7) == 'h');;
}

test "t17" {
    assert (int2str(12) == 'm');;
}

test "t18" {
    assert (int2str(0) == "a");;
}

test "t19" {
    assert (int2str(29) == 'D');;
}

test "t20" {
    assert (int2str(1) == "b");;
}

test "t21" {
    assert (int2str(16) == 'q');;
}

test "t22" {
    assert (int2str(24) == 'y');;
}

test "t23" {
    assert (int2str(26) == 'A');;
}

test "t24" {
    assert (int2str(22) == 'w');;
}

test "t25" {
    assert (int2str(2) == 'c');;
}

test "t26" {
    assert (int2str(52) == '0');;
}

test "t27" {
    assert (int2str(17) == 'r');;
}

test "t28" {
    assert (int2str(27) == "B");;
}

test "t29" {
    assert (int2str(2) == "c");;
}

test "t30" {
    assert (int2str(25) == 'z');;
}

test "t31" {
    assert (int2str(28) == 'C');;
}

test "t32" {
    assert (int2str(52) == "0");;
}

test "t33" {
    assert (int2str(3) == 'd');;
}

test "t34" {
    assert (int2str(61) == '9');;
}

test "t35" {
    assert (int2str(31) == 'F');;
}

test "t36" {
    assert (int2str(27) == 'B');;
}

test "t37" {
    assert (int2str(61) == "9");;
}

test "t38" {
    assert (int2str(51) == 'Z');;
}

test "t39" {
    assert (int2str(26) == "A");;
}

test "t40" {
    assert (int2str(51) == "Z");;
}

test "t41" {
    assert (int2str(4) == 'e');;
}

test "t42" {
    assert (int2str(10) == 'k');;
}

test "t43" {
    assert (int2str(14) == 'o');;
}

test "t44" {
    assert (int2str(19) == 't');;
}
