"""
    Returns a string containing its first argument, and its second argument in upper case.

    :param num: int
    :param string: str
    :return: str
    """
def pos_upper(num: Any, string: Any) -> object {
    return f'{num}:{string.upper()}';
}

test "t0" {
    assert (pos_upper(10, 'fred') == '10:FRED');;
}

test "t1" {
    assert (pos_upper(5, 'bar') == '5:BAR');;
}

test "t2" {
    assert (pos_upper(5, 'foo') == '5:FOO');;
}

test "t3" {
    assert (pos_upper(11, 'School') == '11:SCHOOL');;
}

test "t4" {
    assert (pos_upper(4, 'lower') == '4:LOWER');;
}

test "t5" {
    assert (pos_upper(8, 'javascript') == '8:JAVASCRIPT');;
}

test "t6" {
    assert (pos_upper(3, 'Hello, World!') == '3:HELLO, WORLD!');;
}

test "t7" {
    assert (pos_upper(19, 's') == '19:S');;
}

test "t8" {
    assert (pos_upper(2, 'hEy') == '2:HEY');;
}

test "t9" {
    assert (pos_upper(2, 'lower') == '2:LOWER');;
}

test "t10" {
    assert (pos_upper(5, 'are you good?') == '5:ARE YOU GOOD?');;
}

test "t11" {
    assert (pos_upper(4, 'strawberry') == '4:STRAWBERRY');;
}

test "t12" {
    assert (pos_upper(14, 'n') == '14:N');;
}

test "t13" {
    assert (pos_upper(4, 'd') == '4:D');;
}

test "t14" {
    assert (pos_upper(10, 'python') == '10:PYTHON');;
}

test "t15" {
    assert (pos_upper(3, 'goodbye') == '3:GOODBYE');;
}

test "t16" {
    assert (pos_upper(2, 'string') == '2:STRING');;
}

test "t17" {
    assert (pos_upper(6, 'lower') == '6:LOWER');;
}

test "t18" {
    assert (pos_upper(16, 'p') == '16:P');;
}

test "t19" {
    assert (pos_upper(8, 'h') == '8:H');;
}

test "t20" {
    assert (pos_upper(44, "mandarin orange") == "44:MANDARIN ORANGE");;
}

test "t21" {
    assert (pos_upper(30, "papaya") == "30:PAPAYA");;
}

test "t22" {
    assert (pos_upper(13, 'baz') == '13:BAZ');;
}

test "t23" {
    assert (pos_upper(8, 'lower') == '8:LOWER');;
}

test "t24" {
    assert (pos_upper(10, 'j') == '10:J');;
}

test "t25" {
    assert (pos_upper(2, 'BAR') == '2:BAR');;
}

test "t26" {
    assert (pos_upper(32, "pineapple") == "32:PINEAPPLE");;
}

test "t27" {
    assert (pos_upper(1, 'baz') == '1:BAZ');;
}

test "t28" {
    assert (pos_upper(21, 'lower') == '21:LOWER');;
}

test "t29" {
    assert (pos_upper(3, 'lower') == '3:LOWER');;
}

test "t30" {
    assert (pos_upper(11, 'lower') == '11:LOWER');;
}

test "t31" {
    assert (pos_upper(51, "kiwi") == "51:KIWI");;
}

test "t32" {
    assert (pos_upper(9, 'i') == '9:I');;
}

test "t33" {
    assert (pos_upper(2, 'hi') == '2:HI');;
}

test "t34" {
    assert (pos_upper(10, 'bobby') == '10:BOBBY');;
}

test "t35" {
    assert (pos_upper(1, 'hello world') == '1:HELLO WORLD');;
}

test "t36" {
    assert (pos_upper(19, 'lower') == '19:LOWER');;
}

test "t37" {
    assert (pos_upper(3, 'hi') == '3:HI');;
}

test "t38" {
    assert (pos_upper(20, 't') == '20:T');;
}

test "t39" {
    assert (pos_upper(2, 'hello') == '2:HELLO');;
}

test "t40" {
    assert (pos_upper(5, 'hello') == '5:HELLO');;
}

test "t41" {
    assert (pos_upper(22, 'lower') == '22:LOWER');;
}

test "t42" {
    assert (pos_upper(3, "banana") == "3:BANANA");;
}

test "t43" {
    assert (pos_upper(13, 'm') == '13:M');;
}

test "t44" {
    assert (pos_upper(17, 'q') == '17:Q');;
}

test "t45" {
    assert (pos_upper(4, 'here') == '4:HERE');;
}

test "t46" {
    assert (pos_upper(14, 'lower') == '14:LOWER');;
}

test "t47" {
    assert (pos_upper(0, 'bobby ross') == '0:BOBBY ROSS');;
}

test "t48" {
    assert (pos_upper(16, 'lower') == '16:LOWER');;
}

test "t49" {
    assert (pos_upper(1, 'dog') == '1:DOG');;
}

test "t50" {
    assert (pos_upper(99, 'CAPS') == '99:CAPS');;
}

test "t51" {
    assert (pos_upper(4, 'four') == '4:FOUR');;
}

test "t52" {
    assert (pos_upper(2, 'b') == '2:B');;
}

test "t53" {
    assert (pos_upper(2, 'two') == '2:TWO');;
}

test "t54" {
    assert (pos_upper(7, 'g') == '7:G');;
}

test "t55" {
    assert (pos_upper(1001, 'abcde') == '1001:ABCDE');;
}

test "t56" {
    assert (pos_upper(17, "dragon fruit") == "17:DRAGON FRUIT");;
}

test "t57" {
    assert (pos_upper(4, 'goodbye') == '4:GOODBYE');;
}

test "t58" {
    assert (pos_upper(2, 'baz') == '2:BAZ');;
}

test "t59" {
    assert (pos_upper(78, "watermelon") == "78:WATERMELON");;
}

test "t60" {
    assert (pos_upper(1000, 'pineapple') == '1000:PINEAPPLE');;
}

test "t61" {
    assert (pos_upper(2, 'hey') == '2:HEY');;
}

test "t62" {
    assert (pos_upper(1, 'foo') == '1:FOO');;
}

test "t63" {
    assert (pos_upper(15, 'lower') == '15:LOWER');;
}

test "t64" {
    assert (pos_upper(10, 'lower') == '10:LOWER');;
}

test "t65" {
    assert (pos_upper(18, 'r') == '18:R');;
}

test "t66" {
    assert (pos_upper(15, 'barney') == '15:BARNEY');;
}

test "t67" {
    assert (pos_upper(12, "orange") == "12:ORANGE");;
}

test "t68" {
    assert (pos_upper(9, 'lower') == '9:LOWER');;
}

test "t69" {
    assert (pos_upper(13, 'abc def') == '13:ABC DEF');;
}

test "t70" {
    assert (pos_upper(28, "guava") == "28:GUAVA");;
}

test "t71" {
    assert (pos_upper(1, 'hello') == '1:HELLO');;
}

test "t72" {
    assert (pos_upper(18, 'lower') == '18:LOWER');;
}

test "t73" {
    assert (pos_upper(2, 'three') == '2:THREE');;
}

test "t74" {
    assert (pos_upper(9, 'abc') == '9:ABC');;
}

test "t75" {
    assert (pos_upper(1, 'apple') == '1:APPLE');;
}

test "t76" {
    assert (pos_upper(2, 'world') == '2:WORLD');;
}

test "t77" {
    assert (pos_upper(5, 'bob') == '5:BOB');;
}

test "t78" {
    assert (pos_upper(2, 'bar') == '2:BAR');;
}

test "t79" {
    assert (pos_upper(17, 'lower') == '17:LOWER');;
}

test "t80" {
    assert (pos_upper(3, 'c') == '3:C');;
}

test "t81" {
    assert (pos_upper(12, 'a string') == '12:A STRING');;
}

test "t82" {
    assert (pos_upper(11, 'ABC') == '11:ABC');;
}

test "t83" {
    assert (pos_upper(90, "apple") == "90:APPLE");;
}

test "t84" {
    assert (pos_upper(2, 'hello') == pos_upper(2, 'hello'));;
}

test "t85" {
    assert (pos_upper(1, 'lower') == '1:LOWER');;
}

test "t86" {
    assert (pos_upper(1, 'hElLo') == '1:HELLO');;
}

test "t87" {
    assert (pos_upper(2, 'orange') == '2:ORANGE');;
}

test "t88" {
    assert (pos_upper(13, 'lower') == '13:LOWER');;
}

test "t89" {
    assert (pos_upper(1, 'test') == '1:TEST');;
}

test "t90" {
    assert (pos_upper(6, 'f') == '6:F');;
}

test "t91" {
    assert (pos_upper(3, 'pineapple') == '3:PINEAPPLE');;
}

test "t92" {
    assert (pos_upper(5, 'lower') == '5:LOWER');;
}

test "t93" {
    assert (pos_upper(3, 'bob') == '3:BOB');;
}

test "t94" {
    assert (pos_upper(4, 'elephant') == '4:ELEPHANT');;
}

test "t95" {
    assert (pos_upper(5, '12345') == '5:12345');;
}

test "t96" {
    assert (pos_upper(3, 'bar') == '3:BAR');;
}

test "t97" {
    assert (pos_upper(1, 'APPLE') == '1:APPLE');;
}

test "t98" {
    assert (pos_upper(12, 'l') == '12:L');;
}

test "t99" {
    assert (pos_upper(20, 'lower') == '20:LOWER');;
}

test "t100" {
    assert (pos_upper(3, 'baz') == '3:BAZ');;
}

test "t101" {
    assert (pos_upper(2, 'snake') == '2:SNAKE');;
}

test "t102" {
    assert (pos_upper(3, 'hI') == '3:HI');;
}

test "t103" {
    assert (pos_upper(0, 'cat') == '0:CAT');;
}

test "t104" {
    assert (pos_upper(4, 'howdy') == '4:HOWDY');;
}

test "t105" {
    assert (pos_upper(11, 'bar') == '11:BAR');;
}

test "t106" {
    assert (pos_upper(12, 'lower') == '12:LOWER');;
}

test "t107" {
    assert (pos_upper(1, 'one') == '1:ONE');;
}

test "t108" {
    assert (pos_upper(1, 'a') == '1:A');;
}

test "t109" {
    assert (pos_upper(3, 'foo') == '3:FOO');;
}

test "t110" {
    assert (pos_upper(11, 'k') == '11:K');;
}

test "t111" {
    assert (pos_upper(21, '') == '21:U');;
}

test "t112" {
    assert (pos_upper(5, 'qux') == '5:QUX');;
}

test "t113" {
    assert (pos_upper(3, 'hey') == '3:HEY');;
}

test "t114" {
    assert (pos_upper(7, '100') == '7:100');;
}

test "t115" {
    assert (pos_upper(3, 'three') == '3:THREE');;
}

test "t116" {
    assert (pos_upper(94, "grapefruit") == "94:GRAPEFRUIT");;
}

test "t117" {
    assert (pos_upper(22, 'v') == '22:V');;
}

test "t118" {
    assert (pos_upper(2, 'there') == '2:THERE');;
}

test "t119" {
    assert (pos_upper(100, 'string') == '100:STRING');;
}

test "t120" {
    assert (pos_upper(10, '234$55') == '10:234$55');;
}

test "t121" {
    assert (pos_upper(3, 'd') == '3:D');;
}

test "t122" {
    assert (pos_upper(100, 'banana') == '100:BANANA');;
}

test "t123" {
    assert (pos_upper(4, 'Holberton') == '4:HOLBERTON');;
}

test "t124" {
    assert (pos_upper(3, 'camel') == '3:CAMEL');;
}

test "t125" {
    assert (pos_upper(1, 'hi') == '1:HI');;
}

test "t126" {
    assert (pos_upper(3, 'how are you?') == '3:HOW ARE YOU?');;
}

test "t127" {
    assert (pos_upper(10, 'orange') == '10:ORANGE');;
}

test "t128" {
    assert (pos_upper(5, "apple") == "5:APPLE");;
}

test "t129" {
    assert (pos_upper(15, 'o') == '15:O');;
}

test "t130" {
    assert (pos_upper(7, 'lower') == '7:LOWER');;
}

test "t131" {
    assert (pos_upper(5, 'e') == '5:E');;
}

test "t132" {
    assert (pos_upper(3, 'world') == '3:WORLD');;
}
