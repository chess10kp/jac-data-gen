"""process a string of includes to a set of them"""
def inc_args(s: Any) -> object {
    return `set(
        [
            inc.strip()
            for inc in s.split(" ")
            if inc.strip()
        ]
    );
}

test "t0" {
    assert (inc_args("\n") == `set([]));;
}

test "t1" {
    assert (inc_args("a b c d") == {"a", "b", "c", "d"});;
}

test "t2" {
    assert (inc_args(r"a/b/c a/b/c") == `set([r"a/b/c"]));;
}

test "t3" {
    assert (inc_args("") == `set());;
}

test "t4" {
    assert (
        inc_args(r"a/b/c a/b/c a/b/c a/b/c b/c a/b/c b/c a/b/c a/b/c a/b/c a/b/c")
        == `set([r"a/b/c", r"b/c"])
    );;
}

test "t5" {
    assert (inc_args(r"a/b/c b/c a/b/c b/c a/b/c") == `set([r"a/b/c", r"b/c"]));;
}

test "t6" {
    assert (inc_args("A B") == {"A", "B"});;
}

test "t7" {
    assert (inc_args("    ") == `set());;
}

test "t8" {
    assert (inc_args("a b c d e f g") == `set(["a", "b", "c", "d", "e", "f", "g"]));;
}

test "t9" {
    assert (inc_args("hello     world") == {"hello", "world"});;
}

test "t10" {
    assert (inc_args("a    b c") == {"a", "b", "c"});;
}

test "t11" {
    assert (inc_args("\n \n ") == `set());;
}

test "t12" {
    assert (inc_args(r"foo \bar") == `set(["foo", r"\bar"]));;
}

test "t13" {
    assert (inc_args("A  ") == {"A"});;
}

test "t14" {
    assert (
        inc_args("include1 include2 include3 include4")
        == {"include1", "include2", "include3", "include4"}
    );;
}

test "t15" {
    assert (
        inc_args("include/1  include/2   include/3   include/4   include/5")
        == {"include/1", "include/2", "include/3", "include/4", "include/5"}
    );;
}

test "t16" {
    assert (inc_args("A B C D") == {"A", "B", "C", "D"});;
}

test "t17" {
    assert (inc_args("  a b c ") == `set(["a", "b", "c"]));;
}

test "t18" {
    assert (inc_args("a b c d e f g") == {"a", "b", "c", "d", "e", "f", "g"});;
}

test "t19" {
    assert (inc_args(" ") == `set());;
}

test "t20" {
    assert (
        inc_args(
            "  \t\t \n \n \n  \t  a  \t  \t \n \n \n  \t  b  \t  \t \n \n \n  \t  c  \t  \t \n \n \n  "
        )
        == {"a", "b", "c"}
    );;
}

test "t21" {
    assert (inc_args("""
a.h b.h c.h
""") == {'a.h', 'b.h', 'c.h'});;
}

test "t22" {
    assert (inc_args("a   b   c") == {"a", "b", "c"});;
}

test "t23" {
    assert (inc_args("   ") == `set([]));;
}

test "t24" {
    assert (inc_args(" include/1 include/2") == {"include/1", "include/2"});;
}

test "t25" {
    assert (inc_args("A B  C  D") == {"A", "B", "C", "D"});;
}

test "t26" {
    assert (inc_args(" foo bar ") == `set(["foo", "bar"]));;
}

test "t27" {
    assert (inc_args("a b c d") == {"a", "b", "c", "d"});;
}

test "t28" {
    assert (inc_args("\n") == `set());;
}

test "t29" {
    assert (inc_args("a  b  c") == `set(["a", "b", "c"]));;
}

test "t30" {
    assert (inc_args("include1 include2") == {"include1", "include2"});;
}

test "t31" {
    assert (inc_args("A   B   C") == {"A", "B", "C"});;
}

test "t32" {
    assert (
        inc_args("include include/1 include/2   include/3   include/4   include/5")
        == {"include", "include/1", "include/2", "include/3", "include/4", "include/5"}
    );;
}

test "t33" {
    assert (inc_args("a/ b/ c/") == {"a/", "b/", "c/"});;
}

test "t34" {
    assert (inc_args(r"") == `set());;
}

test "t35" {
    assert (inc_args("  a   b  c  ") == `set(["a", "b", "c"]));;
}

test "t36" {
    assert (inc_args("foo bar") == `set(["foo", "bar"]));;
}

test "t37" {
    assert (inc_args("foo") == `set(["foo"]));;
}

test "t38" {
    assert (inc_args(r"foo bar") == `set(["foo", "bar"]));;
}

test "t39" {
    assert (inc_args(" a b ") == {"a", "b"});;
}

test "t40" {
    assert (inc_args("a b c") == {"a", "b", "c"});;
}

test "t41" {
    assert (inc_args("") == `set([]));;
}

test "t42" {
    assert (inc_args(r'') == `set());;
}

test "t43" {
    assert (inc_args(" ") == `set());;
}

test "t44" {
    assert (inc_args("a b c") == {"a", "b", "c"});;
}

test "t45" {
    assert (inc_args(" a b c ") == {"a", "b", "c"});;
}

test "t46" {
    assert (inc_args("a  b   c  ") == {"a", "b", "c"});;
}

test "t47" {
    assert (inc_args("a") == {"a"});;
}

test "t48" {
    assert (inc_args(r"a/b/c b/c a/b/c b/c") == `set([r"a/b/c", r"b/c"]));;
}

test "t49" {
    assert (inc_args("  ") == `set());;
}

test "t50" {
    assert (inc_args(" a ") == {"a"});;
}

test "t51" {
    assert (inc_args("a b c d e f") == {"a", "b", "c", "d", "e", "f"});;
}

test "t52" {
    assert (inc_args("a b c") == {"a", "b", "c"});;
}

test "t53" {
    assert (inc_args("hello") == {"hello"});;
}

test "t54" {
    assert (inc_args("a       b") == {"a", "b"});;
}

test "t55" {
    assert (inc_args(" ") == `set([]));;
}

test "t56" {
    assert (
        inc_args("a b c d e f g h i j k l m n o p q r s t u v w x y z")
        == {
            "a",
            "b",
            "c",
            "d",
            "e",
            "f",
            "g",
            "h",
            "i",
            "j",
            "k",
            "l",
            "m",
            "n",
            "o",
            "p",
            "q",
            "r",
            "s",
            "t",
            "",
            "v",
            "w",
            "x",
            "y",
            "z"
        }
    );;
}

test "t57" {
    assert (inc_args("  include1") == {"include1"});;
}

test "t58" {
    assert (inc_args("a    b    c") == {"a", "b", "c"});;
}

test "t59" {
    assert (
        inc_args("a b c d e f g h i j k l m n o")
        == {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o"}
    );;
}

test "t60" {
    assert (inc_args("a") == `set(["a"]));;
}

test "t61" {
    assert (inc_args("  ") == `set([]));;
}

test "t62" {
    assert (inc_args("   a     b   ") == {"a", "b"});;
}

test "t63" {
    assert (inc_args("    ") == `set());;
}

test "t64" {
    assert (inc_args("a b c") == `set(["a", "b", "c"]));;
}

test "t65" {
    assert (inc_args(r'a') == {'a'});;
}

test "t66" {
    assert (inc_args("a    b    c    ") == {"a", "b", "c"});;
}

test "t67" {
    assert (inc_args("hello world") == {"hello", "world"});;
}

test "t68" {
    assert (inc_args("a b c ") == `set(["a", "b", "c"]));;
}

test "t69" {
    assert (inc_args("  \t\t\t  ") == `set());;
}

test "t70" {
    assert (inc_args("  a   b c d  ") == {"a", "b", "c", "d"});;
}

test "t71" {
    assert (inc_args(r"a/b/c a/b/c a/b/c") == `set([r"a/b/c"]));;
}

test "t72" {
    assert (inc_args("a     b c     d       e") == {"a", "b", "c", "d", "e"});;
}

test "t73" {
    assert (inc_args("a b") == {"a", "b"});;
}

test "t74" {
    assert (inc_args("A") == {"A"});;
}

test "t75" {
    assert (inc_args("A B C") == {"A", "B", "C"});;
}

test "t76" {
    assert (inc_args("a \n b c") == {"a", "b", "c"});;
}

test "t77" {
    assert (inc_args("a b c d e") == {"a", "b", "c", "d", "e"});;
}

test "t78" {
    assert (inc_args("a  b  c  d") == `set(["a", "b", "c", "d"]));;
}

test "t79" {
    assert (inc_args("  a   b   c  ") == {"a", "b", "c"});;
}

test "t80" {
    assert (inc_args("") == `set());;
}

test "t81" {
    assert (inc_args("a  b  c ") == `set(["a", "b", "c"]));;
}

test "t82" {
    assert (inc_args("   ") == `set());;
}

test "t83" {
    assert (
        inc_args(r"a/b/c a/b/c b/c a/b/c b/c a/b/c a/b/c") == `set([r"a/b/c", r"b/c"])
    );;
}

test "t84" {
    assert (inc_args("\n  foo bar\n") == `set(["foo", "bar"]));;
}

test "t85" {
    assert (inc_args("a     b") == {"a", "b"});;
}

test "t86" {
    assert (inc_args(r'a b') == {'a', 'b'});;
}

test "t87" {
    assert (inc_args(" a b c ") == {"a", "b", "c"});;
}

test "t88" {
    assert (inc_args("test_inc_args.py") == `set(["test_inc_args.py"]));;
}

test "t89" {
    assert (inc_args("a  b   c  ") == {"a", "b", "c"});;
}

test "t90" {
    assert (inc_args("  A  ") == {"A"});;
}

test "t91" {
    assert (inc_args(" a b c ") == {"a", "b", "c"});;
}

test "t92" {
    assert (
        inc_args("include/1 include/2 include/3 include/4 include/5")
        == {"include/1", "include/2", "include/3", "include/4", "include/5"}
    );;
}

test "t93" {
    assert (inc_args(r"a/b/c b/c a/b/c") == `set([r"a/b/c", r"b/c"]));;
}

test "t94" {
    assert (inc_args("\n\n\n") == `set());;
}

test "t95" {
    assert (inc_args(" a b c") == {"a", "b", "c"});;
}

test "t96" {
    assert (inc_args("a b c ") == {"a", "b", "c"});;
}

test "t97" {
    assert (inc_args("a   b") == {"a", "b"});;
}

test "t98" {
    assert (inc_args("  a b c   ") == `set(["a", "b", "c"]));;
}

test "t99" {
    assert (inc_args(" A B C") == {"A", "B", "C"});;
}

test "t100" {
    assert (inc_args("  a b c d e  ") == {"a", "b", "c", "d", "e"});;
}

test "t101" {
    assert (inc_args(" /a/b/c -I/a/b/c ") == `set(["/a/b/c", "-I/a/b/c"]));;
}

test "t102" {
    assert (inc_args("") == `set());;
}

test "t103" {
    assert (inc_args("A B C ") == {"A", "B", "C"});;
}

test "t104" {
    assert (inc_args("A B C  ") == {"A", "B", "C"});;
}

test "t105" {
    assert (inc_args(r"foo") == `set(["foo"]));;
}

test "t106" {
    assert (inc_args(r"a/b/c") == `set([r"a/b/c"]));;
}

test "t107" {
    assert (inc_args("   a    b   c  ") == {"a", "b", "c"});;
}

test "t108" {
    assert (inc_args(r" foo bar ") == `set(["foo", "bar"]));;
}

test "t109" {
    assert (inc_args("a b c ") == {"a", "b", "c"});;
}

test "t110" {
    assert (inc_args(r'a b c') == {'a', 'b', 'c'});;
}

test "t111" {
    assert (inc_args("a") == {"a"});;
}

test "t112" {
    assert (inc_args("\t") == `set([]));;
}
