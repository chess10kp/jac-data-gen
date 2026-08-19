"""
    Forces a value to be within the given min and max value.

    :param value: the value to coerce
    :param min_value: minimum allowed value
    :param max_value: maximum allowed value
    :return: a value within the given range
    """
def coerce(
    value: (int or float), min_value: (int or float), max_value: (int or float)
) -> (int or float) {
    if (value < min_value) {
        return min_value;
    }
    if (value > max_value) {
        return max_value;
    }
    return value;
}

test "t0" {
    assert (coerce(1e-05, 0, 1) == 1e-05);;
}

test "t1" {
    assert (coerce(1, 1, 10) == 1);;
}

test "t2" {
    assert (coerce(0, 0, 10) == 0);;
}

test "t3" {
    assert (coerce(1.5, 1, 10) == 1.5);;
}

test "t4" {
    assert (coerce(-10, -10, -10) == -10);;
}

test "t5" {
    assert (coerce(999, -1000, 1000) == 999);;
}

test "t6" {
    assert (coerce(4, 0, 5) == 4);;
}

test "t7" {
    assert (coerce(50.0, 0, 100) == 50.0);;
}

test "t8" {
    assert (coerce(-100.1, 0, 100) == 0);;
}

test "t9" {
    assert (coerce(10, 1, 10) == 10);;
}

test "t10" {
    assert (coerce(4, 3.0, 5.0) == 4.0);;
}

test "t11" {
    assert (coerce(2.2, 2.2, 2.2) == 2.2);;
}

test "t12" {
    assert (coerce(0, 1, 10) == 1);;
}

test "t13" {
    assert (coerce(-100, 0, 100) == 0);;
}

test "t14" {
    assert (coerce(11, 0, 10) == 10);;
}

test "t15" {
    assert (coerce(3, 2, 3) == 3);;
}

test "t16" {
    assert (coerce(2, 1, 3) == 2);;
}

test "t17" {
    assert (coerce(1, 2, 2) == 2);;
}

test "t18" {
    assert (coerce(50.0, 0.0, 100.0) == 50.0);;
}

test "t19" {
    assert (coerce(1.0, 0, 2) == 1.0);;
}

test "t20" {
    assert (coerce(0, 0, 100) == 0);;
}

test "t21" {
    assert (coerce(100, 100, 100) == 100);;
}

test "t22" {
    assert (coerce(2, 1, 2) == 2);;
}

test "t23" {
    assert (coerce(6.0, 3.0, 5.0) == 5.0);;
}

test "t24" {
    assert (coerce(0, 1, 100) == 1);;
}

test "t25" {
    assert (coerce(90, -1, -1) == -1);;
}

test "t26" {
    assert (coerce(2.0, 3, 5.0) == 3.0);;
}

test "t27" {
    assert (coerce(1, 1, 3) == 1);;
}

test "t28" {
    assert (coerce(10.0, 1, 10) == 10);;
}

test "t29" {
    assert (coerce(50, 1, 100) == 50);;
}

test "t30" {
    assert (coerce(10.5, 0, 10) == 10);;
}

test "t31" {
    assert (coerce(2.2, 3.3, 1.1) == 3.3);;
}

test "t32" {
    assert (coerce(50, 0, 100) == 50);;
}

test "t33" {
    assert (coerce(-20, -10, 10) == -10);;
}

test "t34" {
    assert (coerce(-10, 10, 100) == 10);;
}

test "t35" {
    assert (coerce(-10, -100, -10) == -10);;
}

test "t36" {
    assert (coerce(-1, -1, -1) == -1);;
}

test "t37" {
    assert (coerce(1.0, 1.0, 1.0) == 1.0);;
}

test "t38" {
    assert (coerce(-1, 1, 10) == 1);;
}

test "t39" {
    assert (coerce(10, 10, 20) == 10);;
}

test "t40" {
    assert (coerce(50, 0.0, 100.0) == 50.0);;
}

test "t41" {
    assert (coerce(0.5, 0, 1) == 0.5);;
}

test "t42" {
    assert (coerce(10.1, 0, 100) == 10.1);;
}

test "t43" {
    assert (coerce(2, 3.0, 5) == 3);;
}

test "t44" {
    assert (coerce(4, 0, 10) == 4);;
}

test "t45" {
    assert (coerce(100, 0, 0) == 0);;
}

test "t46" {
    assert (coerce(2, 2, 4) == 2);;
}

test "t47" {
    assert (coerce(100, -1, -1) == -1);;
}

test "t48" {
    assert (coerce(100.0, 0.0, 100.0) == 100.0);;
}

test "t49" {
    assert (coerce(6, 3, 5) == 5);;
}

test "t50" {
    assert (coerce(1000, -1000, 1000) == 1000);;
}

test "t51" {
    assert (coerce(100, 0, 10) == 10);;
}

test "t52" {
    assert (coerce(1, 1, 1) == 1);;
}

test "t53" {
    assert (coerce(1000, 0, 100) == 100);;
}

test "t54" {
    assert (coerce(1000, 10, 100) == 100);;
}

test "t55" {
    assert (coerce(4.0, 3, 5) == 4.0);;
}

test "t56" {
    assert (coerce(20, 0, 10) == 10);;
}

test "t57" {
    assert (coerce(2.2, 1.1, 1.1) == 1.1);;
}

test "t58" {
    assert (coerce(2.0, 3, 5) == 3.0);;
}

test "t59" {
    assert (coerce(2.0, 3.0, 5.0) == 3.0);;
}

test "t60" {
    assert (coerce(100, 10, 100) == 100);;
}

test "t61" {
    assert (coerce(3.0, 2, 3) == 3.0);;
}

test "t62" {
    assert (coerce(4, 1, 3) == 3);;
}

test "t63" {
    assert (coerce(1, 0, 10) == 1);;
}

test "t64" {
    assert (coerce(1, 1, 100) == 1);;
}

test "t65" {
    assert (coerce(1, 1, 2) == 1);;
}

test "t66" {
    assert (coerce(2, 1, 1) == 1);;
}

test "t67" {
    assert (coerce(1.0, 1, 2) == 1.0);;
}

test "t68" {
    assert (coerce(2, -1000, 1000) == 2);;
}

test "t69" {
    assert (coerce(20, -10, 10) == 10);;
}

test "t70" {
    assert (coerce(10, 10, 10) == 10);;
}

test "t71" {
    assert (coerce(2, 3, 5) == 3);;
}

test "t72" {
    assert (coerce(10, 0, 0) == 0);;
}

test "t73" {
    assert (coerce(4, 2, 4) == 4);;
}

test "t74" {
    assert (coerce(3, 2, 4) == 3);;
}

test "t75" {
    assert (coerce(100, 1, 10) == 10);;
}

test "t76" {
    assert (coerce(3, 0, 10) == 3);;
}

test "t77" {
    assert (coerce(-1, 0, 10) == 0);;
}

test "t78" {
    assert (coerce(100, 0, 100) == 100);;
}

test "t79" {
    assert (coerce(50, 10, 100) == 50);;
}

test "t80" {
    assert (coerce(10.1, 1, 10) == 10);;
}

test "t81" {
    assert (coerce(20, 1, 10) == 10);;
}

test "t82" {
    assert (coerce(10, 0, 100) == 10);;
}

test "t83" {
    assert (coerce(6.0, 3, 5) == 5.0);;
}

test "t84" {
    assert (coerce(1.0, 0, 1) == 1.0);;
}

test "t85" {
    assert (coerce(10, 1, 100) == 10);;
}

test "t86" {
    assert (coerce(-10, 0, 100) == 0);;
}

test "t87" {
    assert (coerce(90, 0, 0) == 0);;
}

test "t88" {
    assert (coerce(1, -1000, 1000) == 1);;
}

test "t89" {
    assert (coerce(6, 3.0, 5.0) == 5.0);;
}

test "t90" {
    assert (coerce(4.0, 3.0, 5.0) == 4.0);;
}

test "t91" {
    assert (coerce(0.9, 0, 1) == 0.9);;
}

test "t92" {
    assert (coerce(0.5, 0, 10) == 0.5);;
}

test "t93" {
    assert (coerce(6.0, 3, 5.0) == 5.0);;
}

test "t94" {
    assert (coerce(2.2, 1.1, 3.3) == 2.2);;
}

test "t95" {
    assert (coerce(4, 3.0, 5) == 4);;
}

test "t96" {
    assert (coerce(0, 1, 1) == 1);;
}

test "t97" {
    assert (coerce(42, 10, 100) == 42);;
}

test "t98" {
    assert (coerce(-10, 0, 10) == 0);;
}

test "t99" {
    assert (coerce(6.7, 0, 5) == 5);;
}

test "t100" {
    assert (coerce(5, 1, 10) == 5);;
}

test "t101" {
    assert (coerce(0, 1, 3) == 1);;
}

test "t102" {
    assert (coerce(3, 1, 3) == 3);;
}

test "t103" {
    assert (coerce(42, 10, 43) == 42);;
}

test "t104" {
    assert (coerce(1, 0, 0) == 0);;
}

test "t105" {
    assert (coerce(1, 0, 2) == 1);;
}

test "t106" {
    assert (coerce(-10.1, 0, 100) == 0);;
}

test "t107" {
    assert (coerce(-0.5, 0, 10) == 0);;
}

test "t108" {
    assert (coerce(-5, -10, 10) == -5);;
}

test "t109" {
    assert (coerce(6, 3.0, 5) == 5);;
}

test "t110" {
    assert (coerce(1, 10, 100) == 10);;
}

test "t111" {
    assert (coerce(100, 1, 100) == 100);;
}

test "t112" {
    assert (coerce(2.5, 2, 3) == 2.5);;
}

test "t113" {
    assert (coerce(0.0, 0.0, 100.0) == 0.0);;
}

test "t114" {
    assert (coerce(1, 0, 1) == 1);;
}

test "t115" {
    assert (coerce(110, 10, 100) == 100);;
}

test "t116" {
    assert (coerce(2, 3, 1) == 3);;
}

test "t117" {
    assert (coerce(20, 10, 20) == 20);;
}

test "t118" {
    assert (coerce(0, 0, 0) == 0);;
}

test "t119" {
    assert (coerce(90, 10, 100) == 90);;
}

test "t120" {
    assert (coerce(11, 1, 10) == 10);;
}

test "t121" {
    assert (coerce(4, 2, 3) == 3);;
}

test "t122" {
    assert (coerce(2.5, 0, 5) == 2.5);;
}

test "t123" {
    assert (coerce(2, 0, 1) == 1);;
}

test "t124" {
    assert (coerce(4.0, 3, 5.0) == 4.0);;
}

test "t125" {
    assert (coerce(5, 2, 4) == 4);;
}

test "t126" {
    assert (coerce(-99, -1000, 1000) == -99);;
}

test "t127" {
    assert (coerce(42, 43, 43) == 43);;
}

test "t128" {
    assert (coerce(0, 1, 2) == 1);;
}

test "t129" {
    assert (coerce(2.0, 2, 3) == 2);;
}

test "t130" {
    assert (coerce(100, 99, 100) == 100);;
}

test "t131" {
    assert (coerce(10, 0, 10) == 10);;
}

test "t132" {
    assert (coerce(0, -1000, 1000) == 0);;
}

test "t133" {
    assert (coerce(-1, 1, 100) == 1);;
}

test "t134" {
    assert (coerce(-1, 0, 1) == 0);;
}

test "t135" {
    assert (coerce(4, 3, 5) == 4);;
}

test "t136" {
    assert (coerce(100.0, 0, 100) == 100.0);;
}

test "t137" {
    assert (coerce(2, 2, 2) == 2);;
}

test "t138" {
    assert (coerce(50, 0, 0) == 0);;
}

test "t139" {
    assert (coerce(5, 0, 10) == 5);;
}

test "t140" {
    assert (coerce(1001, -1000, 1000) == 1000);;
}

test "t141" {
    assert (coerce(-1, 0, 5) == 0);;
}

test "t142" {
    assert (coerce(2, 3.0, 5.0) == 3.0);;
}

test "t143" {
    assert (coerce(11, -10, 10) == 10);;
}

test "t144" {
    assert (coerce(10, 10, 100) == 10);;
}

test "t145" {
    assert (coerce(-100, -100, -100) == -100);;
}

test "t146" {
    assert (coerce(5.5, 1, 10) == 5.5);;
}

test "t147" {
    assert (coerce(1, -10, 10) == 1);;
}

test "t148" {
    assert (coerce(42, 40, 43) == 42);;
}

test "t149" {
    assert (coerce(5, 0, 5) == 5);;
}

test "t150" {
    assert (coerce(2, 2, 3) == 2);;
}

test "t151" {
    assert (coerce(100, 100, 101) == 100);;
}

test "t152" {
    assert (coerce(10, -10, 10) == 10);;
}

test "t153" {
    assert (coerce(0.0, 0, 100) == 0.0);;
}

test "t154" {
    assert (coerce(0, 0, 1) == 0);;
}

test "t155" {
    assert (coerce(3, 1, 2) == 2);;
}

test "t156" {
    assert (coerce(0, -10, 10) == 0);;
}
