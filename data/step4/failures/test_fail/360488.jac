""" Maps the sign of the number to -1 or 1"""
def sign(number: int) -> int {
    if (number < 0) {
        return -1;
    } else {
        return 1;
    }
}

test "t0" {
    assert (sign(5) == 1);;
}

test "t1" {
    assert (sign(-1000000) == -1);;
}

test "t2" {
    assert (sign(-456) == -1);;
}

test "t3" {
    assert (sign(0) == 1);;
}

test "t4" {
    assert (sign(-1000) == -1);;
}

test "t5" {
    assert (sign(1000) == 1);;
}

test "t6" {
    assert (sign(100000000) == 1);;
}

test "t7" {
    assert (sign(-2147483647) == -1);;
}

test "t8" {
    assert (sign(-12) == -1);;
}

test "t9" {
    assert (sign(-1000000000000.5) == -1);;
}

test "t10" {
    assert (sign(-1.2) == -1);;
}

test "t11" {
    assert (sign(1000000) == 1);;
}

test "t12" {
    assert (sign(1.0) == 1);;
}

test "t13" {
    assert (sign(-0.001) == -1);;
}

test "t14" {
    assert (sign(-1000000000000) == -1);;
}

test "t15" {
    assert (sign(4) == 1);;
}

test "t16" {
    assert (sign(3000) == 1);;
}

test "t17" {
    assert (sign(1000000000000) == 1);;
}

test "t18" {
    assert (sign(5.0) == 1);;
}

test "t19" {
    assert (sign(1.2) == 1);;
}

test "t20" {
    assert (sign(-3) == -1);;
}

test "t21" {
    assert (sign(-inf) == -1);;
}

test "t22" {
    assert (sign(-100000000) == -1);;
}

test "t23" {
    assert (sign(0.0) == 1);;
}

test "t24" {
    assert (sign(-21) == -1);;
}

test "t25" {
    assert (sign(-1e+100) == -1);;
}

test "t26" {
    assert (sign(3) == 1);;
}

test "t27" {
    assert (sign(0.5) == 1);;
}

test "t28" {
    assert (sign(1.1) == 1);;
}

test "t29" {
    assert (sign(int(-1)) == -1);;
}

test "t30" {
    assert (sign(-2) == -1);;
}

test "t31" {
    assert (sign(-1.5) == -1);;
}

test "t32" {
    assert (sign(1000000000000.5) == 1);;
}

test "t33" {
    assert (sign(10000000000.0) == 1);;
}

test "t34" {
    assert (sign(1e-100) == 1);;
}

test "t35" {
    assert (sign(-1.0) == -1);;
}

test "t36" {
    assert (sign(100) == 1);;
}

test "t37" {
    assert (sign(-2000) == -1);;
}

test "t38" {
    assert (sign(-43) == -1);;
}

test "t39" {
    assert (sign(-1e-100) == -1);;
}

test "t40" {
    assert (sign(-5) == -1);;
}

test "t41" {
    assert (sign(2) == 1);;
}

test "t42" {
    assert (sign(-1) == -1);;
}

test "t43" {
    assert (sign(0.0) == 1);;
}

test "t44" {
    assert (sign(-5.0) == -1);;
}

test "t45" {
    assert (sign(2147483647) == 1);;
}

test "t46" {
    assert (sign(32) == 1);;
}

test "t47" {
    assert (sign(10.5) == 1);;
}

test "t48" {
    assert (sign(1) == 1);;
}

test "t49" {
    assert (sign(inf) == 1);;
}

test "t50" {
    assert (sign(-10.5) == -1);;
}

test "t51" {
    assert (sign(10) == 1);;
}

test "t52" {
    assert (sign(0.001) == 1);;
}

test "t53" {
    assert (sign(12) == 1);;
}

test "t54" {
    assert (sign(-34) == -1);;
}

test "t55" {
    assert (sign(2.0) == 1);;
}

test "t56" {
    assert (sign(1e+100) == 1);;
}

test "t57" {
    assert (sign(-1.1) == -1);;
}

test "t58" {
    assert (sign(-2.0) == -1);;
}

test "t59" {
    assert (sign(1e-10) == 1);;
}

test "t60" {
    assert (sign(-10) == -1);;
}

test "t61" {
    assert (sign(21) == 1);;
}

test "t62" {
    assert (sign(123) == 1);;
}

test "t63" {
    assert (sign(2.75) == 1);;
}

test "t64" {
    assert (sign(42) == 1);;
}

test "t65" {
    assert (sign(42.0) == 1);;
}

test "t66" {
    assert (sign(-100) == -1);;
}
