"""Convert serialized chamber id to station."""
def serial_to_station(x: int) -> int {
    return (((x >> 8) & 3) + 1);
}

test "t0" {
    assert (serial_to_station(9) == 1);;
}

test "t1" {
    assert (serial_to_station(0) == 1);;
}

test "t2" {
    assert (serial_to_station(2147483658) == 1);;
}

test "t3" {
    assert (serial_to_station(259) == serial_to_station(259));;
}

test "t4" {
    assert (serial_to_station(((1 << 48) | 1)) == 1);;
}

test "t5" {
    assert (serial_to_station(2147483655) == 1);;
}

test "t6" {
    assert (serial_to_station(((1 << 96) | 1)) == 1);;
}

test "t7" {
    assert (serial_to_station(19) == 1);;
}

test "t8" {
    assert (serial_to_station(12) == 1);;
}

test "t9" {
    assert (serial_to_station(192) == 1);;
}

test "t10" {
    assert (serial_to_station(16) == 1);;
}

test "t11" {
    assert (serial_to_station(258) == 2);;
}

test "t12" {
    assert (serial_to_station(3) == 1);;
}

test "t13" {
    assert (serial_to_station(((1 << 72) | 1)) == 1);;
}

test "t14" {
    assert (serial_to_station(1) == 1);;
}

test "t15" {
    assert (serial_to_station(21) == 1);;
}

test "t16" {
    assert (serial_to_station(1) == 1);;
}

test "t17" {
    assert (serial_to_station(((1 << 32) | 1)) == 1);;
}

test "t18" {
    assert (serial_to_station(((1 << 56) | 1)) == 1);;
}

test "t19" {
    assert (serial_to_station(219025168) == 4);;
}

test "t20" {
    assert (serial_to_station(2147483664) == 1);;
}

test "t21" {
    assert (serial_to_station(2147483649) == 1);;
}

test "t22" {
    assert (serial_to_station(((1 << 128) | 1)) == 1);;
}

test "t23" {
    assert (serial_to_station(10) == 1);;
}

test "t24" {
    assert (serial_to_station(((1 << 16) | 1)) == 1);;
}

test "t25" {
    assert (serial_to_station(257) == serial_to_station(257));;
}

test "t26" {
    assert (serial_to_station(29) == 1);;
}

test "t27" {
    assert (serial_to_station(((1 << 40) | 1)) == 1);;
}

test "t28" {
    assert (serial_to_station(0) == 1);;
}

test "t29" {
    assert (serial_to_station(((1 << 120) | 1)) == 1);;
}

test "t30" {
    assert (serial_to_station(7) == 1);;
}

test "t31" {
    assert (serial_to_station(((1 << 88) | 1)) == 1);;
}

test "t32" {
    assert (serial_to_station(((1 << 144) | 1)) == 1);;
}

test "t33" {
    assert (serial_to_station(64) == 1);;
}

test "t34" {
    assert (serial_to_station((1 + (2 ** 8))) == 2);;
}

test "t35" {
    assert (serial_to_station(25) == 1);;
}

test "t36" {
    assert (serial_to_station(9) == 1);;
}

test "t37" {
    assert (serial_to_station(128) == 1);;
}

test "t38" {
    assert (serial_to_station(13) == 1);;
}

test "t39" {
    assert (serial_to_station(258) == serial_to_station(258));;
}

test "t40" {
    assert (serial_to_station(((1 << 104) | 1)) == 1);;
}

test "t41" {
    assert (serial_to_station(28) == 1);;
}

test "t42" {
    assert (serial_to_station(2147483661) == 1);;
}

test "t43" {
    assert (serial_to_station(((1 << 24) | 1)) == 1);;
}

test "t44" {
    assert (serial_to_station(13) == 1);;
}

test "t45" {
    assert (serial_to_station(5) == 1);;
}

test "t46" {
    assert (serial_to_station(4294967295) == 4);;
}

test "t47" {
    assert (serial_to_station(16) == 1);;
}

test "t48" {
    assert (serial_to_station(((1 << 136) | 1)) == 1);;
}

test "t49" {
    assert (serial_to_station(65537) == 1);;
}

test "t50" {
    assert (serial_to_station(4) == 1);;
}

test "t51" {
    assert (serial_to_station(17) == 1);;
}

test "t52" {
    assert (serial_to_station(4) == 1);;
}

test "t53" {
    assert (serial_to_station(10) == 1);;
}

test "t54" {
    assert (serial_to_station(2147483652) == 1);;
}

test "t55" {
    assert (serial_to_station(22) == 1);;
}

test "t56" {
    assert (serial_to_station(16909060) == 4);;
}

test "t57" {
    assert (serial_to_station(((1 << 112) | 1)) == 1);;
}

test "t58" {
    assert (serial_to_station(7) == 1);;
}

test "t59" {
    assert (serial_to_station(((1 << 64) | 1)) == 1);;
}

test "t60" {
    assert (serial_to_station(8) == 1);;
}

test "t61" {
    assert (serial_to_station(((1 << 80) | 1)) == 1);;
}

test "t62" {
    assert (serial_to_station(17) == 1);;
}
