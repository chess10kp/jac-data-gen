def inc_args(s):
    """process a string of includes to a set of them"""
    return set([inc.strip() for inc in s.split(" ") if inc.strip()])

assert inc_args("\n") == set([])
assert inc_args( "a b c d" ) == {"a", "b", "c", "d"}
assert inc_args(r"a/b/c a/b/c") == set([r"a/b/c"])
assert inc_args(    "",       ) == set()
assert inc_args(r"a/b/c a/b/c a/b/c a/b/c b/c a/b/c b/c a/b/c a/b/c a/b/c a/b/c") == set([r"a/b/c", r"b/c"])
assert inc_args(r"a/b/c b/c a/b/c b/c a/b/c") == set([r"a/b/c", r"b/c"])
assert inc_args("A B") == {"A", "B"}
assert inc_args(    "    ",    ) == set()
assert inc_args("a b c d e f g") == set(["a", "b", "c", "d", "e", "f", "g"])
assert inc_args("hello     world") == {"hello", "world"}
assert inc_args( "a    b c" ) == {"a", "b", "c"}
assert inc_args(
    "\n \n "
) == set()
assert inc_args(r"foo \bar") == set(["foo", r"\bar"])
assert inc_args("A  ") == {"A"}
assert inc_args(
    "include1 include2 include3 include4"
) == {"include1", "include2", "include3", "include4"}
assert inc_args(
    "include/1  include/2   include/3   include/4   include/5"
) == {"include/1", "include/2", "include/3", "include/4", "include/5"}
assert inc_args("A B C D") == {"A", "B", "C", "D"}
assert inc_args("  a b c ") == set(["a", "b", "c"])
assert inc_args("a b c d e f g") == {"a", "b", "c", "d", "e", "f", "g"}
assert inc_args(" ") == set()
assert inc_args(
    "  \t\t \n \n \n  \t  a  \t  \t \n \n \n  \t  b  \t  \t \n \n \n  \t  c  \t  \t \n \n \n  "
) == {"a", "b", "c"}
assert inc_args(
    """
a.h b.h c.h
"""
) == {'a.h', 'b.h', 'c.h'}
assert inc_args("a   b   c") == {"a", "b", "c"}
assert inc_args("   ") == set([])
assert inc_args(" include/1 include/2") == {"include/1", "include/2"}
assert inc_args(
    "A B  C  D"
) == {"A", "B", "C", "D"}
assert inc_args(" foo bar ") == set(["foo", "bar"])
assert inc_args("a b c d") == {"a", "b", "c", "d"}
assert inc_args(
    "\n"
) == set()
assert inc_args("a  b  c") == set(["a", "b", "c"])
assert inc_args(
    "include1 include2"
) == {"include1", "include2"}
assert inc_args("A   B   C") == {"A", "B", "C"}
assert inc_args(
    "include include/1 include/2   include/3   include/4   include/5"
) == {"include", "include/1", "include/2", "include/3", "include/4", "include/5"}
assert inc_args("a/ b/ c/") == {"a/", "b/", "c/"}
assert inc_args(r"") == set()
assert inc_args(
    "  a   b  c  "
) == set(["a", "b", "c"])
assert inc_args("foo bar") == set(["foo", "bar"])
assert inc_args("foo") == set(["foo"])
assert inc_args(r"foo bar") == set(["foo", "bar"])
assert inc_args(" a b ") == {"a", "b"}
assert inc_args( "a b c" ) == {"a", "b", "c"}
assert inc_args("") == set([])
assert inc_args(r'') == set()
assert inc_args(
    " "
) == set()
assert inc_args("a b c") == {"a", "b", "c"}
assert inc_args( " a b c " ) == {"a", "b", "c"}
assert inc_args(    "a  b   c  ",    ) == {"a", "b", "c"}
assert inc_args(
    "a"
) == {"a"}
assert inc_args(r"a/b/c b/c a/b/c b/c") == set([r"a/b/c", r"b/c"])
assert inc_args("  ") == set()
assert inc_args(" a ") == {"a"}
assert inc_args( "a b c d e f" ) == {"a", "b", "c", "d", "e", "f"}
assert inc_args(
    "a b c"
) == {"a", "b", "c"}
assert inc_args("hello") == {"hello"}
assert inc_args("a       b") == {"a", "b"}
assert inc_args(" ") == set([])
assert inc_args( "a b c d e f g h i j k l m n o p q r s t u v w x y z" ) == \
    {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "", "v", "w", "x", "y", "z"}
assert inc_args("  include1") == {"include1"}
assert inc_args( "a    b    c" ) == {"a", "b", "c"}
assert inc_args("a b c d e f g h i j k l m n o") == {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o"}
assert inc_args("a") == set(["a"])
assert inc_args("  ") == set([])
assert inc_args("   a     b   ") == {"a", "b"}
assert inc_args(    "    "   ) == set()
assert inc_args("a b c") == set(["a", "b", "c"])
assert inc_args(r'a') == {'a'}
assert inc_args( "a    b    c    " ) == {"a", "b", "c"}
assert inc_args("hello world") == {"hello", "world"}
assert inc_args("a b c ") == set(["a", "b", "c"])
assert inc_args(
    "  \t\t\t  "
) == set()
assert inc_args("  a   b c d  ") == {"a", "b", "c", "d"}
assert inc_args(r"a/b/c a/b/c a/b/c") == set([r"a/b/c"])
assert inc_args("a     b c     d       e") == {"a", "b", "c", "d", "e"}
assert inc_args("a b") == {"a", "b"}
assert inc_args("A") == {"A"}
assert inc_args("A B C") == {"A", "B", "C"}
assert inc_args(
    "a \n b c"
) == {"a", "b", "c"}
assert inc_args("a b c d e") == {"a", "b", "c", "d", "e"}
assert inc_args("a  b  c  d") == set(["a", "b", "c", "d"])
assert inc_args(
    "  a   b   c  "
) == {"a", "b", "c"}
assert inc_args(
    ""
) == set()
assert inc_args("a  b  c ") == set(["a", "b", "c"])
assert inc_args(    "   ",    ) == set()
assert inc_args(r"a/b/c a/b/c b/c a/b/c b/c a/b/c a/b/c") == set([r"a/b/c", r"b/c"])
assert inc_args("\n  foo bar\n") == set(["foo", "bar"])
assert inc_args("a     b") == {"a", "b"}
assert inc_args(r'a b') == {'a', 'b'}
assert inc_args(" a b c ") == {"a", "b", "c"}
assert inc_args("test_inc_args.py") == set(["test_inc_args.py"])
assert inc_args(    "a  b   c  "   ) == {"a", "b", "c"}
assert inc_args("  A  ") == {"A"}
assert inc_args(
    " a b c "
) == {"a", "b", "c"}
assert inc_args(
    "include/1 include/2 include/3 include/4 include/5"
) == {"include/1", "include/2", "include/3", "include/4", "include/5"}
assert inc_args(r"a/b/c b/c a/b/c") == set([r"a/b/c", r"b/c"])
assert inc_args(
    "\n\n\n"
) == set()
assert inc_args(" a b c") == {"a", "b", "c"}
assert inc_args("a b c ") == {"a", "b", "c"}
assert inc_args("a   b") == {"a", "b"}
assert inc_args("  a b c   ") == set(["a", "b", "c"])
assert inc_args(" A B C") == {"A", "B", "C"}
assert inc_args("  a b c d e  ") == {"a", "b", "c", "d", "e"}
assert inc_args(" /a/b/c -I/a/b/c ") == set(["/a/b/c", "-I/a/b/c"])
assert inc_args("") == set()
assert inc_args("A B C ") == {"A", "B", "C"}
assert inc_args("A B C  ") == {"A", "B", "C"}
assert inc_args(r"foo") == set(["foo"])
assert inc_args(r"a/b/c") == set([r"a/b/c"])
assert inc_args("   a    b   c  ") == {"a", "b", "c"}
assert inc_args(r" foo bar ") == set(["foo", "bar"])
assert inc_args( "a b c " ) == {"a", "b", "c"}
assert inc_args(r'a b c') == {'a', 'b', 'c'}
assert inc_args("a") == {"a"}
assert inc_args("\t") == set([])
