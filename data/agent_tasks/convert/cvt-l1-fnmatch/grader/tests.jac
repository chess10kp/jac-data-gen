# Hidden tests: CPython Lib/test/test_fnmatch.py (v3.12.7), str cases with POSIX semantics
# (normcase is the identity: case-sensitive, '\\' and '/' are distinct), ported to Jac.
import re;
import string;
import from glob_match { fnmatch, fnmatchcase, filter, translate }

glob TESTCASES: str = string.ascii_lowercase + string.digits + string.punctuation;

def ok(name: str, pat: str) -> bool {
    return fnmatch(name, pat);
}

test "fnmatch basics" {
    assert ok("abc", "abc");
    assert ok("abc", "?*?");
    assert ok("abc", "???*");
    assert ok("abc", "*???");
    assert ok("abc", "???");
    assert ok("abc", "*");
    assert ok("abc", "ab[cd]");
    assert ok("abc", "ab[!de]");
    assert not ok("abc", "ab[de]");
    assert not ok("a", "??");
    assert ok("\\", r"[\]");
    assert ok("a", r"[!\]");
    assert not ok("\\", r"[!\]");
    assert ok("foo\nbar", "foo*");
    assert ok("foo\nbar\n", "foo*");
    assert not ok("\nfoo", "foo*");
    assert ok("\n", "*");
}

test "no catastrophic backtracking" {
    assert ok("a" * 50, "*a*a*a*a*a*a*a*a*a*a");
    assert not ok(("a" * 50) + "b", "*a*a*a*a*a*a*a*a*a*a");
}

test "fnmatchcase and posix case/sep" {
    assert fnmatchcase("abc", "abc");
    assert not fnmatchcase("AbC", "abc");
    assert not fnmatchcase("abc", "AbC");
    assert fnmatchcase("AbC", "AbC");
    assert fnmatchcase("usr/bin", "usr/bin");
    assert not fnmatchcase("usr\\bin", "usr/bin");
    assert not fnmatchcase("usr/bin", "usr\\bin");
    assert fnmatchcase("usr\\bin", "usr\\bin");
    assert not ok("AbC", "abc");
    assert not ok("usr\\bin", "usr/bin");
}

test "char sets" {
    for c in TESTCASES {
        assert ok(c, "[az]") == (c in "az");
        assert ok(c, "[!az]") == (c not in "az");
        assert not ok(c, "[AZ]") or c in "AZ";
        assert ok(c, "[aa]") == (c == "a");
        assert ok(c, "[^az]") == (c in "^az");
        assert ok(c, "[[az]") == (c in "[az");
        assert ok(c, r"[!]]") == (c != "]");
    }
    for c in string.ascii_uppercase {
        assert not ok(c, "[az]");
        assert ok(c, "[!az]");
    }
    assert ok("[", "[");
    assert ok("[]", "[]");
    assert ok("[!", "[!");
    assert ok("[!]", "[!]");
}

test "ranges" {
    for c in TESTCASES {
        assert ok(c, "[b-d]") == (c in "bcd");
        assert ok(c, "[!b-d]") == (c not in "bcd");
        assert ok(c, "[b-dx-z]") == (c in "bcdxyz");
        assert ok(c, "[!b-dx-z]") == (c not in "bcdxyz");
        assert not ok(c, "[B-D]") or c in "BCD";
        assert ok(c, "[b-b]") == (c == "b");
        assert ok(c, "[!-#]") == (c not in "-#");
        assert ok(c, "[!--.]") == (c not in "-.");
        assert ok(c, "[^-`]") == (c in "^_`");
        assert ok(c, "[[-^]") == (c in r"[\]^");
        assert ok(c, r"[\-^]") == (c in r"\]^");
        assert ok(c, "[-]") == (c in "-");
        assert ok(c, "[!-]") == (c not in "-");
        assert not ok(c, "[d-b]");
        assert ok(c, "[!d-b]");
        assert ok(c, "[d-bx-z]") == (c in "xyz");
        assert ok(c, "[!d-bx-z]") == (c not in "xyz");
        assert ok(c, "[d-b^-`]") == (c in "^_`");
        assert ok(c, "[d-b[-^]") == (c in r"[\]^");
    }
}

test "separators in sets and ranges" {
    assert ok("/", r"[/]");
    assert ok("\\", r"[\]");
    assert not ok("/", r"[\]");
    assert not ok("\\", r"[/]");
    assert not ok("[/]", r"[/]");
    assert not ok(r"[\\]", r"[/]");
    assert ok("\\", r"[\t]");
    assert not ok("/", r"[\t]");
    assert ok("t", r"[\t]");
    assert not ok("\t", r"[\t]");
    assert ok("a/b", "a[.-0]b");
    assert not ok("a\\b", "a[.-0]b");
    assert ok("a\\b", "a[Z-^]b");
    assert not ok("a/b", "a[Z-^]b");
    assert ok("a/b", "a[/-0]b");
    assert not ok(r"a\b", "a[/-0]b");
    assert not ok("a[/-0]b", "a[/-0]b");
    assert ok("a/b", "a[.-/]b");
    assert not ok(r"a\b", "a[.-/]b");
    assert ok(r"a\b", r"a[\-^]b");
    assert not ok("a/b", r"a[\-^]b");
    assert not ok(r"a[\-^]b", r"a[\-^]b");
    assert ok(r"a\b", r"a[Z-\]b");
    assert not ok("a/b", r"a[Z-\]b");
}

test "set operation characters are literal" {
    assert ok("[", "[[]");
    assert ok("&", "[a&&b]");
    assert ok("|", "[a||b]");
    assert ok("~", "[a~~b]");
    assert ok(",", "[a-z+--A-Z]");
    assert ok(".", "[a-z--/A-Z]");
}

test "translate" {
    assert translate("*") == r"(?s:.*)\Z";
    assert translate("?") == r"(?s:.)\Z";
    assert translate("a?b*") == r"(?s:a.b.*)\Z";
    assert translate("[abc]") == r"(?s:[abc])\Z";
    assert translate("[]]") == r"(?s:[]])\Z";
    assert translate("[!x]") == r"(?s:[^x])\Z";
    assert translate("[^x]") == r"(?s:[\^x])\Z";
    assert translate("[x") == r"(?s:\[x)\Z";
    assert translate("*.txt") == r"(?s:.*\.txt)\Z";
    assert translate("*********") == r"(?s:.*)\Z";
    assert translate("A*********") == r"(?s:A.*)\Z";
    assert translate("*********A") == r"(?s:.*A)\Z";
    assert translate("A*********?[?]?") == r"(?s:A.*.[?].)\Z";
    assert translate("**a*a****a") == r"(?s:(?>.*?a)(?>.*?a).*a)\Z";
    fatre = "|".join([translate("**a**a**a*"), translate("**b**b**b*"), translate("*c*c*c*")]);
    assert re.match(fatre, "abaccad") is not None;
    assert re.match(fatre, "cbabcaxc") is not None;
    assert re.match(fatre, "dabccbad") is None;
}

test "filter" {
    assert filter(["Python", "Ruby", "Perl", "Tcl"], "P*") == ["Python", "Perl"];
    assert filter(["Test.py", "Test.rb", "Test.PL"], "*.p*") == ["Test.py"];
    assert filter(["Test.py", "Test.rb", "Test.PL"], "*.P*") == ["Test.PL"];
    assert filter(["usr/bin", "usr", "usr\\lib"], "usr/*") == ["usr/bin"];
    assert filter(["usr/bin", "usr", "usr\\lib"], "usr\\*") == ["usr\\lib"];
    assert len(filter(["x", "y"], "z*")) == 0;
}
