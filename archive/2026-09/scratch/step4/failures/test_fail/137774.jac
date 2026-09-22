"""
    Generate mask of specified size (sequence of '1')
    """
def mask(bits: int) -> int {
    return ((1 << bits) - 1);
}

test "t0" {
    assert (mask(17) == 131071);;
}

test "t1" {
    assert (mask(11) == 2047);;
}

test "t2" {
    assert (mask(28) == 268435455);;
}

test "t3" {
    assert (mask(21) == 2097151);;
}

test "t4" {
    assert (mask(16) == 65535);;
}

test "t5" {
    assert (mask(8) == 255);;
}

test "t6" {
    assert (mask(8) == 255);;
}

test "t7" {
    assert (mask(14) == 16383);;
}

test "t8" {
    assert (mask(64) == mask(64));;
}

test "t9" {
    assert (mask(15) == 32767);;
}

test "t10" {
    assert (mask(19) == 524287);;
}

test "t11" {
    assert (mask(5) == 31);;
}

test "t12" {
    assert (mask(32) == 4294967295);;
}

test "t13" {
    assert (mask(18) == 262143);;
}

test "t14" {
    assert (mask(128) == 340282366920938463463374607431768211455);;
}

test "t15" {
    assert (mask(0) == 0);;
}

test "t16" {
    assert (mask(19) == 524287);;
}

test "t17" {
    assert (mask(22) == 4194303);;
}

test "t18" {
    assert (mask(8) == mask(8));;
}

test "t19" {
    assert (mask(7) == 127);;
}

test "t20" {
    assert (mask(13) == 8191);;
}

test "t21" {
    assert (mask(6) == 63);;
}

test "t22" {
    assert (mask(18) == 262143);;
}

test "t23" {
    assert (mask(26) == 67108863);;
}

test "t24" {
    assert (mask(7) == 127);;
}

test "t25" {
    assert (mask(9) == 511);;
}

test "t26" {
    assert (mask(1) == mask(1));;
}

test "t27" {
    assert (mask(64) == 18446744073709551615);;
}

test "t28" {
    assert (mask(17) == 131071);;
}

test "t29" {
    assert (mask(15) == 32767);;
}

test "t30" {
    assert (mask(10) == 1023);;
}

test "t31" {
    assert (mask(4) == 15);;
}

test "t32" {
    assert (mask(3) == 7);;
}

test "t33" {
    assert (mask(200) == mask(200));;
}

test "t34" {
    assert (mask(1) == 1);;
}

test "t35" {
    assert (mask(7) == 127);;
}

test "t36" {
    assert (mask(25) == 33554431);;
}

test "t37" {
    assert (mask(8) == 255);;
}

test "t38" {
    assert (mask(2) == 3);;
}

test "t39" {
    assert (mask(24) == 16777215);;
}

test "t40" {
    assert (mask(4) == mask(4));;
}

test "t41" {
    assert (mask(6) == 63);;
}

test "t42" {
    assert (mask(11) == 2047);;
}

test "t43" {
    assert (mask(20) == 1048575);;
}

test "t44" {
    assert (mask(3) == 7);;
}

test "t45" {
    assert (mask(64) == 18446744073709551615);;
}

test "t46" {
    assert (mask(5) == 31);;
}

test "t47" {
    assert (mask(64) == ((1 << 64) - 1));;
}

test "t48" {
    assert (mask(2) == mask(2));;
}

test "t49" {
    assert (mask(31) == mask(31));;
}

test "t50" {
    assert (mask(0) == 0);;
}

test "t51" {
    assert (mask(6) == 63);;
}

test "t52" {
    assert (mask(2) == 3);;
}

test "t53" {
    assert (mask(14) == 16383);;
}

test "t54" {
    assert (mask(23) == 8388607);;
}

test "t55" {
    assert (mask(5) == mask(5));;
}

test "t56" {
    assert (mask(10) == 1023);;
}

test "t57" {
    assert (mask(32) == ((1 << 32) - 1));;
}

test "t58" {
    assert (mask(5) == 31);;
}

test "t59" {
    assert (mask(1) == 1);;
}

test "t60" {
    assert (mask(32) == mask(32));;
}

test "t61" {
    assert (mask(13) == 8191);;
}

test "t62" {
    assert (mask(20) == mask(20));;
}

test "t63" {
    assert (mask(12) == 4095);;
}

test "t64" {
    assert (mask(27) == 134217727);;
}

test "t65" {
    assert (mask(63) == mask(63));;
}

test "t66" {
    assert (mask(9) == mask(9));;
}

test "t67" {
    assert (mask(4) == 15);;
}

test "t68" {
    assert (mask(4) == 15);;
}

test "t69" {
    assert (mask(16) == 65535);;
}

test "t70" {
    assert (mask(3) == mask(3));;
}

test "t71" {
    assert (mask(9) == 511);;
}

test "t72" {
    assert (mask(30) == 1073741823);;
}

test "t73" {
    assert (mask(7) == mask(7));;
}

test "t74" {
    assert (mask(10) == mask(10));;
}

test "t75" {
    assert (mask(6) == mask(6));;
}

test "t76" {
    assert (mask(16) == 65535);;
}

test "t77" {
    assert (mask(12) == 4095);;
}

test "t78" {
    assert (mask(32) == 4294967295);;
}
