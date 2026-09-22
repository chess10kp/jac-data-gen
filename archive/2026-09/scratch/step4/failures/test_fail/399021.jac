"""Convert string to natural number."""
def str_to_nat(s: Any) -> object {
    return (ord(s) - ord("a"));
}

test "t0" {
    assert (str_to_nat(chr(107)) == 10);;
}

test "t1" {
    assert (str_to_nat("k") == 10);;
}

test "t2" {
    assert (str_to_nat(chr(109)) == 12);;
}

test "t3" {
    assert (str_to_nat(chr(112)) == 15);;
}

test "t4" {
    assert (str_to_nat(chr(103)) == 6);;
}

test "t5" {
    assert (str_to_nat(chr((ord("a") + 4))) == 4);;
}

test "t6" {
    assert (str_to_nat(chr(118)) == 21);;
}

test "t7" {
    assert (str_to_nat("") == 20);;
}

test "t8" {
    assert (str_to_nat("i") == 8);;
}

test "t9" {
    assert (str_to_nat("h") == 7);;
}

test "t10" {
    assert (str_to_nat("s") == 18);;
}

test "t11" {
    assert (str_to_nat("z") == 25);;
}

test "t12" {
    assert (str_to_nat("q") == 16);;
}

test "t13" {
    assert (str_to_nat(chr((ord("a") + 0))) == 0);;
}

test "t14" {
    assert (str_to_nat(chr((ord("a") + 15))) == 15);;
}

test "t15" {
    assert (str_to_nat("z") == 25);;
}

test "t16" {
    assert (str_to_nat(chr(110)) == 13);;
}

test "t17" {
    assert (str_to_nat(chr((ord("a") + 7))) == 7);;
}

test "t18" {
    assert (str_to_nat("m") == 12);;
}

test "t19" {
    assert (str_to_nat(chr((ord("a") + 14))) == 14);;
}

test "t20" {
    assert (str_to_nat(chr(106)) == 9);;
}

test "t21" {
    assert (str_to_nat("n") == 13);;
}

test "t22" {
    assert (str_to_nat(chr((ord("a") + 1))) == 1);;
}

test "t23" {
    assert (str_to_nat("l") == 11);;
}

test "t24" {
    assert (str_to_nat(chr(105)) == 8);;
}

test "t25" {
    assert (str_to_nat(chr((ord("a") + 2))) == 2);;
}

test "t26" {
    assert (str_to_nat(chr(111)) == 14);;
}

test "t27" {
    assert (str_to_nat(chr(100)) == 3);;
}

test "t28" {
    assert (str_to_nat("b") == 1);;
}

test "t29" {
    assert (str_to_nat(chr(116)) == 19);;
}

test "t30" {
    assert (str_to_nat("v") == 21);;
}

test "t31" {
    assert (str_to_nat(chr((ord("a") + 16))) == 16);;
}

test "t32" {
    assert (str_to_nat(chr(114)) == 17);;
}

test "t33" {
    assert (str_to_nat(chr(102)) == 5);;
}

test "t34" {
    assert (str_to_nat(chr(99)) == 2);;
}

test "t35" {
    assert (str_to_nat("g") == 6);;
}

test "t36" {
    assert (str_to_nat(chr((ord("a") + 10))) == 10);;
}

test "t37" {
    assert (str_to_nat(chr((ord("a") + 8))) == 8);;
}

test "t38" {
    assert (str_to_nat(chr((ord("a") + 6))) == 6);;
}

test "t39" {
    assert (str_to_nat("p") == 15);;
}

test "t40" {
    assert (str_to_nat(chr((ord("a") + 11))) == 11);;
}

test "t41" {
    assert (str_to_nat(chr(104)) == 7);;
}

test "t42" {
    assert (str_to_nat("a") == 0);;
}

test "t43" {
    assert (str_to_nat("r") == 17);;
}

test "t44" {
    assert (str_to_nat("e") == 4);;
}

test "t45" {
    assert (str_to_nat("j") == 9);;
}

test "t46" {
    assert (str_to_nat(chr((ord("a") + 17))) == 17);;
}

test "t47" {
    assert (str_to_nat("t") == 19);;
}

test "t48" {
    assert (str_to_nat(chr(98)) == 1);;
}

test "t49" {
    assert (str_to_nat("b") == 1);;
}

test "t50" {
    assert (str_to_nat("a") == 0);;
}

test "t51" {
    assert (str_to_nat("o") == 14);;
}

test "t52" {
    assert (str_to_nat(chr(113)) == 16);;
}

test "t53" {
    assert (str_to_nat(chr(119)) == 22);;
}

test "t54" {
    assert (str_to_nat(chr(115)) == 18);;
}

test "t55" {
    assert (str_to_nat(chr((ord("a") + 13))) == 13);;
}

test "t56" {
    assert (str_to_nat("y") == 24);;
}

test "t57" {
    assert (str_to_nat("w") == 22);;
}

test "t58" {
    assert (str_to_nat("d") == 3);;
}

test "t59" {
    assert (str_to_nat("x") == 23);;
}

test "t60" {
    assert (str_to_nat("f") == 5);;
}

test "t61" {
    assert (str_to_nat(chr((ord("a") + 3))) == 3);;
}

test "t62" {
    assert (str_to_nat(chr(101)) == 4);;
}

test "t63" {
    assert (str_to_nat(chr(97)) == 0);;
}

test "t64" {
    assert (str_to_nat(chr((ord("a") + 5))) == 5);;
}

test "t65" {
    assert (str_to_nat(chr((ord("a") + 9))) == 9);;
}

test "t66" {
    assert (str_to_nat(chr(117)) == 20);;
}

test "t67" {
    assert (str_to_nat("z") == 25);;
}

test "t68" {
    assert (str_to_nat(chr((ord("a") + 12))) == 12);;
}

test "t69" {
    assert (str_to_nat("a") == 0);;
}

test "t70" {
    assert (str_to_nat("c") == 2);;
}

test "t71" {
    assert (str_to_nat("c") == 2);;
}

test "t72" {
    assert (str_to_nat(chr(108)) == 11);;
}
