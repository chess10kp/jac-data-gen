# Hidden tests: CPython test_posixpath.py / test_genericpath.py (v3.12.7), str cases, ported to Jac.
import from pure_paths { isabs, join, split, splitext, splitroot, basename, dirname, normpath, commonprefix, commonpath }

glob NORMPATH_CASES: list[tuple[str, str]] = [
    ("", "."), ("/", "/"), ("/.", "/"), ("/./", "/"), ("/.//.", "/"), ("/foo", "/foo"),
    ("/foo/bar", "/foo/bar"), ("//", "//"), ("///", "/"), ("///foo/.//bar//", "/foo/bar"),
    ("///foo/.//bar//.//..//.//baz///", "/foo/baz"), ("///..//./foo/.//bar", "/foo/bar"),
    (".", "."), (".//.", "."), ("..", ".."), ("../", ".."), ("../foo", "../foo"),
    ("../../foo", "../../foo"), ("../foo/../bar", "../bar"),
    ("../../foo/../bar/./baz/boom/..", "../../bar/baz"), ("/..", "/"), ("/../", "/"),
    ("/..//", "/"), ("//.", "//"), ("//..", "//"), ("//...", "//..."), ("//../foo", "//foo"),
    ("//../../foo", "//foo"), ("/../foo", "/foo"), ("/../../foo", "/foo"), ("/../foo/../", "/"),
    ("/../foo/../bar", "/bar"), ("/../../foo/../bar/./baz/boom/..", "/bar/baz"),
    ("/../../foo/../bar/./baz/boom/.", "/bar/baz/boom"), ("foo/../bar/baz", "bar/baz"),
    ("foo/../../bar/baz", "../bar/baz"), ("foo/../../../bar/baz", "../../bar/baz"),
    ("foo///../bar/.././../baz/boom", "../baz/boom"), ("foo/bar/../..///../../baz/boom", "../../baz/boom"),
    ("/foo/..", "/"), ("/foo/../..", "/"), ("//foo/..", "//"), ("//foo/../..", "//"),
    ("///foo/..", "/"), ("///foo/../..", "/"), ("////foo/..", "/"), ("/////foo/..", "/")
];

glob SPLITEXT_CASES: list[tuple[str, str, str]] = [
    ("foo.bar", "foo", ".bar"), ("foo.boo.bar", "foo.boo", ".bar"),
    ("foo.boo.biff.bar", "foo.boo.biff", ".bar"), (".csh.rc", ".csh", ".rc"),
    ("nodots", "nodots", ""), (".cshrc", ".cshrc", ""), ("...manydots", "...manydots", ""),
    ("...manydots.ext", "...manydots", ".ext"), (".", ".", ""), ("..", "..", ""),
    ("........", "........", ""), ("", "", "")
];

def commonpath_error(paths: list[str]) -> bool {
    try {
        commonpath(paths);
    } except ValueError {
        return True;
    }
    return False;
}

test "join" {
    assert join("/foo", "bar", "/bar", "baz") == "/bar/baz";
    assert join("/foo", "bar", "baz") == "/foo/bar/baz";
    assert join("/foo/", "bar/", "baz/") == "/foo/bar/baz/";
    assert join("a") == "a";
    assert join("", "b") == "b";
    assert join("a", "") == "a/";
}

test "split" {
    assert split("/foo/bar") == ("/foo", "bar");
    assert split("/") == ("/", "");
    assert split("foo") == ("", "foo");
    assert split("////foo") == ("////", "foo");
    assert split("//foo//bar") == ("//foo", "bar");
}

test "splitext" {
    for (path, filename, ext) in SPLITEXT_CASES {
        assert splitext(path) == (filename, ext);
        assert splitext("/" + path) == ("/" + filename, ext);
        assert splitext("abc/" + path) == ("abc/" + filename, ext);
        assert splitext("abc.def/" + path) == ("abc.def/" + filename, ext);
        assert splitext("/abc.def/" + path) == ("/abc.def/" + filename, ext);
        assert splitext(path + "/") == (filename + ext + "/", "");
    }
}

test "splitroot" {
    assert splitroot("") == ("", "", "");
    assert splitroot("a") == ("", "", "a");
    assert splitroot("a/b/") == ("", "", "a/b/");
    assert splitroot("/a") == ("", "/", "a");
    assert splitroot("/a/b/") == ("", "/", "a/b/");
    assert splitroot("//a") == ("", "//", "a");
    assert splitroot("///a") == ("", "/", "//a");
    assert splitroot("c:/a/b") == ("", "", "c:/a/b");
    assert splitroot("\\/a/b") == ("", "", "\\/a/b");
}

test "isabs" {
    assert isabs("") is False;
    assert isabs("/") is True;
    assert isabs("/foo") is True;
    assert isabs("/foo/bar") is True;
    assert isabs("foo/bar") is False;
}

test "basename" {
    assert basename("/foo/bar") == "bar";
    assert basename("/") == "";
    assert basename("foo") == "foo";
    assert basename("////foo") == "foo";
    assert basename("//foo//bar") == "bar";
}

test "dirname" {
    assert dirname("/foo/bar") == "/foo";
    assert dirname("/") == "/";
    assert dirname("foo") == "";
    assert dirname("////foo") == "////";
    assert dirname("//foo//bar") == "//foo";
}

test "normpath" {
    for (path, expected) in NORMPATH_CASES {
        assert normpath(path) == expected, path;
    }
}

test "commonprefix" {
    assert commonprefix([]) == "";
    assert commonprefix(["/home/swenson/spam", "/home/swen/spam"]) == "/home/swen";
    assert commonprefix(["/home/swen/spam", "/home/swen/eggs"]) == "/home/swen/";
    assert commonprefix(["/home/swen/spam", "/home/swen/spam"]) == "/home/swen/spam";
    assert commonprefix(["home:swenson:spam", "home:swen:spam"]) == "home:swen";
    assert commonprefix([":home:swen:spam", ":home:swen:eggs"]) == ":home:swen:";
    assert commonprefix([":home:swen:spam", ":home:swen:spam"]) == ":home:swen:spam";
    testlist = ["", "abc", "Xbcd", "Xb", "XY", "abcd", "aXc", "abd", "ab", "aX", "abcX"];
    for s1 in testlist {
        for s2 in testlist {
            p = commonprefix([s1, s2]);
            assert s1.startswith(p) and s2.startswith(p);
            if s1 != s2 {
                n = len(p);
                assert s1[n:n + 1] != s2[n:n + 1];
            }
        }
    }
}

test "commonpath" {
    assert commonpath_error([]);
    assert commonpath_error(["/usr", "usr"]);
    assert commonpath_error(["usr", "/usr"]);
    assert commonpath_error(["", "/spam/alot"]);
    assert commonpath(["/usr/local"]) == "/usr/local";
    assert commonpath(["/usr/local", "/usr/local"]) == "/usr/local";
    assert commonpath(["/usr/local/", "/usr/local"]) == "/usr/local";
    assert commonpath(["/usr/local/", "/usr/local/"]) == "/usr/local";
    assert commonpath(["/usr//local", "//usr/local"]) == "/usr/local";
    assert commonpath(["/usr/./local", "/./usr/local"]) == "/usr/local";
    assert commonpath(["/", "/dev"]) == "/";
    assert commonpath(["/usr", "/dev"]) == "/";
    assert commonpath(["/usr/lib/", "/usr/lib64/"]) == "/usr";
    assert commonpath(["/usr/lib/", "/usr/lib64"]) == "/usr";
    assert commonpath(["spam"]) == "spam";
    assert commonpath(["spam", "spam"]) == "spam";
    assert commonpath(["spam", "alot"]) == "";
    assert commonpath(["and/jam", "and/spam"]) == "and";
    assert commonpath(["and//jam", "and/spam//"]) == "and";
    assert commonpath(["and/./jam", "./and/spam"]) == "and";
    assert commonpath(["and/jam", "and/spam", "alot"]) == "";
    assert commonpath(["and/jam", "and/spam", "and"]) == "and";
    assert commonpath([""]) == "";
    assert commonpath(["", "spam/alot"]) == "";
}
