"""Trims all lone trailing zeros in the version string after major/minor.

    Examples:
      10.0.0.0 -> 10.0
      10.0.0.1 -> 10.0.0.1
      10.0.0-abc1 -> 10.0.0-abc1
      10.0.0-abc1.0 -> 10.0.0-abc1
    """
def trimVersionString(version_string: Any) -> object {
    if ((version_string == None) or (version_string == '')) {
        return '';
    }
    version_parts = version_string.split('.');
    while ((len(version_parts) > 2) and (version_parts[-1] == '0')) {
        delete(version_parts[-1],);
    }
    return '.'.join(version_parts);
}

test "t0" {
    assert (trimVersionString('0') == '0');;
}

test "t1" {
    assert (trimVersionString('10.0.0.0.0.1') == '10.0.0.0.0.1');;
}

test "t2" {
    assert (trimVersionString('10.1.0') == '10.1');;
}

test "t3" {
    assert (trimVersionString('10.0.0') == '10.0');;
}

test "t4" {
    assert (trimVersionString('1.0.0.1') == '1.0.0.1');;
}

test "t5" {
    assert (trimVersionString('10.0.0-abc1.0.0') == '10.0.0-abc1');;
}

test "t6" {
    assert (trimVersionString('') == '');;
}

test "t7" {
    assert (trimVersionString('10.0.0.0.0.0') == '10.0');;
}

test "t8" {
    assert (trimVersionString('10.0.0.0-abc1.0') == '10.0.0.0-abc1');;
}

test "t9" {
    assert (trimVersionString('1.0.0.0') == '1.0');;
}

test "t10" {
    assert (trimVersionString('10.0') == '10.0');;
}

test "t11" {
    assert (trimVersionString('0.1') == '0.1');;
}

test "t12" {
    assert (trimVersionString(None) == '');;
}

test "t13" {
    assert (trimVersionString('10.0.0.0.0') == '10.0');;
}

test "t14" {
    assert (trimVersionString('10.1.0.0') == '10.1');;
}

test "t15" {
    assert (trimVersionString('10.1') == '10.1');;
}

test "t16" {
    assert (trimVersionString('1.0') == '1.0');;
}

test "t17" {
    assert (trimVersionString('10.0.0.0') == '10.0');;
}

test "t18" {
    assert (trimVersionString('10.0.1.0.0.1') == '10.0.1.0.0.1');;
}

test "t19" {
    assert (trimVersionString('10.0.0-abc1.0') == '10.0.0-abc1');;
}

test "t20" {
    assert (trimVersionString('10.0.0.1') == '10.0.0.1');;
}

test "t21" {
    assert (trimVersionString('10.0.0.0.1.0') == '10.0.0.0.1');;
}

test "t22" {
    assert (trimVersionString('0.0') == '0.0');;
}

test "t23" {
    assert (trimVersionString('1.0.1') == '1.0.1');;
}

test "t24" {
    assert (trimVersionString('10.0.0.1.0.0.0') == '10.0.0.1');;
}

test "t25" {
    assert (trimVersionString('10.0.0.0-abc1') == '10.0.0.0-abc1');;
}

test "t26" {
    assert (trimVersionString('1.0.0') == '1.0');;
}

test "t27" {
    assert (trimVersionString('10.0.0-abc1') == '10.0.0-abc1');;
}
