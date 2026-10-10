# Hidden tests: python-json-pointer 3.2.0 tests.py (+ module doctests) ported to Jac.
import copy;
import from json_pointer { JsonPointer, JsonPointerException, EndOfList, resolve_pointer, set_pointer, escape, unescape, pairwise }

def spec_doc -> dict[str, any] {
    return {"foo": ["bar", "baz"], "": 0, "a/b": 1, "c%d": 2, "e^f": 3, "g|h": 4,
            "i\\j": 5, "k\"l": 6, " ": 7, "m~n": 8};
}

def raises_jpe(f: any) -> bool {
    try {
        f();
    } except JsonPointerException {
        return True;
    }
    return False;
}

test "specification examples" {
    doc = spec_doc();
    assert resolve_pointer(doc, "") == doc;
    assert list(resolve_pointer(doc, "/foo")) == ["bar", "baz"];
    assert resolve_pointer(doc, "/foo/0") == "bar";
    assert resolve_pointer(doc, "/") == 0;
    assert resolve_pointer(doc, "/a~1b") == 1;
    assert resolve_pointer(doc, "/c%d") == 2;
    assert resolve_pointer(doc, "/e^f") == 3;
    assert resolve_pointer(doc, "/g|h") == 4;
    assert resolve_pointer(doc, "/i\\j") == 5;
    assert resolve_pointer(doc, "/k\"l") == 6;
    assert resolve_pointer(doc, "/ ") == 7;
    assert resolve_pointer(doc, "/m~0n") == 8;
}

test "end of list" {
    doc = {"foo": ["bar", "baz"]};
    eol = resolve_pointer(doc, "/foo/-");
    assert isinstance(eol, EndOfList);
    assert repr(eol) == "EndOfList(['bar', 'baz'])";
    assert raises_jpe(lambda -> any { return resolve_pointer(doc, "/foo/-/1"); });
}

test "round trip and parts" {
    cases: list[tuple[str, list[str]]] = [("", []), ("/foo", ["foo"]), ("/foo/0", ["foo", "0"]), ("/", [""]),
             ("/a~1b", ["a/b"]), ("/c%d", ["c%d"]), ("/e^f", ["e^f"]), ("/g|h", ["g|h"]),
             ("/i\\j", ["i\\j"]), ("/k\"l", ["k\"l"]), ("/ ", [" "]), ("/m~0n", ["m~n"]), ("/\xee", ["\xee"])];
    for (path, parts) in cases {
        ptr = JsonPointer(path);
        assert ptr.path == path;
        assert list(ptr.get_parts()) == list(ptr.parts);
        assert len(ptr.get_parts()) == len(parts);
        assert all(a == b for (a, b) in zip(ptr.get_parts(), parts));
        assert JsonPointer.from_parts(ptr.get_parts()) == ptr;
    }
}

test "str and repr" {
    for (path, rep) in [("", "JsonPointer('')"), ("/foo/0", "JsonPointer('/foo/0')"),
                        ("/a~1b", "JsonPointer('/a~1b')"), ("/i\\j", "JsonPointer('/i\\\\j')"),
                        ("/k\"l", "JsonPointer('/k\"l')"), ("/m~0n", "JsonPointer('/m~0n')"),
                        ("/\xee", "JsonPointer('/\xee')")] {
        ptr = JsonPointer(path);
        assert str(ptr) == path;
        assert repr(ptr) == rep;
    }
}

test "equality and hash" {
    p1 = JsonPointer("/something/1/b");
    p2 = JsonPointer("/something/1/b");
    p3 = JsonPointer("/something/1.0/b");
    assert p1 == p2 and p1 != p3 and p2 != p3;
    assert hash(p1) == hash(p2) and hash(p1) != hash(p3);
    assert not (p1 == "/something/1/b");
    assert len({p1, p2, p3}) == 2;
}

test "contains" {
    ptr1 = JsonPointer("/a/b/c");
    ptr2 = JsonPointer("/a/b");
    ptr3 = JsonPointer("/b/c");
    assert ptr1.contains(ptr2) and ptr1.contains(ptr1) and not ptr1.contains(ptr3);
    assert ptr2 in ptr1 and ptr1 in ptr1 and ptr3 not in ptr1;
}

test "join and slash operator" {
    ptr1 = JsonPointer("/a/b/c");
    ptr2 = JsonPointer("/a/b");
    assert ptr1.join(ptr2).path == "/a/b/c/a/b";
    assert ptr1.join(ptr2.parts).path == "/a/b/c/a/b";
    assert ptr1.join(ptr2.parts[0:1]).path == "/a/b/c/a";
    assert ptr1.join("/a/b").path == "/a/b/c/a/b";
    assert ptr1.join(["a", "b"]).path == "/a/b/c/a/b";
    assert raises_jpe(lambda -> any { return ptr1.join(0); });
    assert (ptr1 / ptr2).path == "/a/b/c/a/b";
    assert (ptr1 / ["a", "b"]).path == "/a/b/c/a/b";
    assert (ptr1 / "/a/b").path == "/a/b/c/a/b";
    assert (JsonPointer("/a~1b") / "/m~0n").path == "/a~1b/m~0n";
    assert (JsonPointer("/a") / JsonPointer("/b") / ["c"]).path == "/a/b/c";
    assert JsonPointer.from_parts(["a", "~", "/", 0]).path == "/a/~0/~1/0";
    assert ptr1.path == "/a/b/c";
}

test "wrong input" {
    assert raises_jpe(lambda -> any { return JsonPointer("some/thing"); });
    assert raises_jpe(lambda -> any { return resolve_pointer([0, 1, 2], "/a"); });
    assert raises_jpe(lambda -> any { return resolve_pointer([0, 1, 2], "/10"); });
    assert raises_jpe(lambda -> any { return JsonPointer("/foo/bar~"); });
    assert raises_jpe(lambda -> any { return JsonPointer("/foo/bar~2"); });
    assert raises_jpe(lambda -> any { return resolve_pointer([0, 1, 2], "/01"); });
    doc = {"foo": "should-not-be-indexable"};
    assert raises_jpe(lambda -> any { return resolve_pointer(doc, "/foo/0"); });
    assert raises_jpe(lambda -> any { return JsonPointer("/foo/0").resolve(doc); });
    assert resolve_pointer([0, 1, 2], "/2") == 2;
}

test "missing member message names the document" {
    doc = {"foo": 1};
    msg = "";
    try {
        resolve_pointer(doc, "/bar");
    } except JsonPointerException as e {
        msg = str(e);
    }
    assert "bar" in msg and repr(doc) in msg;
}

test "defaults" {
    doc = {"foo": {"anArray": [{"prop": 44}], "another prop": {"baz": "A string"}}, "a%20b": 1, "c d": 2};
    assert resolve_pointer(doc, "/some/path", None) is None;
    assert resolve_pointer(doc, "/a b", None) is None;
    assert resolve_pointer(doc, "/a%20b") == 1;
    assert resolve_pointer(doc, "/c d") == 2;
    assert resolve_pointer(doc, "/c%20d", None) is None;
    assert resolve_pointer(doc, "/foo/another prop/baz") == "A string";
    marker = object();
    assert resolve_pointer([0], "/5", marker) is marker;
    assert resolve_pointer({"items": [0]}, "/items/9", marker) is marker;
    assert JsonPointer("/x").get({"x": 3}) == 3;
}

test "to_last" {
    doc = {"a": [1, 2, 3]};
    (last, nxt) = JsonPointer("").to_last(doc);
    assert last == doc and nxt is None;
    doc2 = {"a": [{"b": 1, "c": 2}, 5]};
    (last2, nxt2) = JsonPointer("/a/0/b").to_last(doc2);
    assert last2 == {"b": 1, "c": 2} and nxt2 == "b";
    (last3, nxt3) = JsonPointer("/a/1").to_last(doc2);
    assert nxt3 == 1 and isinstance(nxt3, int);
}

test "set not in place" {
    doc = spec_doc();
    orig = copy.deepcopy(doc);
    newdoc = set_pointer(doc, "/foo/1", "cod", inplace=False);
    assert resolve_pointer(newdoc, "/foo/1") == "cod";
    assert len(doc["foo"]) == 2;
    newdoc = set_pointer(doc, "/foo/-", "xyz", inplace=False);
    assert resolve_pointer(newdoc, "/foo/2") == "xyz";
    assert len(doc["foo"]) == 2 and len(newdoc["foo"]) == 3;
    newdoc = set_pointer(doc, "/", 9, inplace=False);
    assert resolve_pointer(newdoc, "/") == 9;
    newdoc = set_pointer(doc, "/fud", {}, inplace=False);
    newdoc = set_pointer(newdoc, "/fud/gaw", [1, 2, 3], inplace=False);
    assert resolve_pointer(newdoc, "/fud") == {"gaw": [1, 2, 3]};
    assert set_pointer(doc, "", 9, inplace=False) == 9;
    assert doc == orig;
}

test "set in place" {
    doc = spec_doc();
    set_pointer(doc, "/foo/1", "cod");
    assert resolve_pointer(doc, "/foo/1") == "cod";
    set_pointer(doc, "/foo/-", "xyz");
    assert resolve_pointer(doc, "/foo/2") == "xyz";
    assert len(doc["foo"]) == 3;
    set_pointer(doc, "/", 9);
    assert resolve_pointer(doc, "/") == 9;
    assert raises_jpe(lambda -> any { return set_pointer(doc, "/fud/gaw", 9); });
    set_pointer(doc, "/fud", {});
    set_pointer(doc, "/fud/gaw", [1, 2, 3]);
    assert resolve_pointer(doc, "/fud") == {"gaw": [1, 2, 3]};
    assert raises_jpe(lambda -> any { return set_pointer(doc, "", 9); });
    assert raises_jpe(lambda -> any { return set_pointer({"s": "abc"}, "/s/0", "x"); });
    assert raises_jpe(lambda -> any { return set_pointer([1], "/5", "x"); });
}

obj TreeNode {
    has name: str;
    has parent: TreeNode | None = None;
    has left: TreeNode | None = None;
    has right: TreeNode | None = None;

    def set_left(n: TreeNode) {
        n.parent = self;
        self.left = n;
    }

    def set_right(n: TreeNode) {
        n.parent = self;
        self.right = n;
    }

    def __getitem__(key: str) -> TreeNode | None {
        if key == "left" {
            return self.left;
        }
        if key == "right" {
            return self.right;
        }
        raise KeyError("Only left and right supported");
    }

    def __setitem__(key: str, val: TreeNode) {
        if key == "left" {
            self.set_left(val);
            return;
        }
        if key == "right" {
            self.set_right(val);
            return;
        }
        raise KeyError(f"Only left and right supported: {key}");
    }
}

obj MockDict {
    has d: dict[str, any];

    def __getitem__(item: str) -> any {
        return self.d[item];
    }
}

test "alternative indexable types" {
    top = TreeNode(name="root");
    a = TreeNode(name="a");
    b = TreeNode(name="b");
    top.set_left(a);
    a.set_left(TreeNode(name="aa"));
    a.set_right(TreeNode(name="ab"));
    top.set_right(b);
    b.set_left(TreeNode(name="ba"));
    b.set_right(TreeNode(name="bb"));
    assert resolve_pointer(top, "/left").name == "a";
    assert resolve_pointer(top, "/left/right").name == "ab";
    assert resolve_pointer(top, "/right/left").name == "ba";
    newtop = set_pointer(top, "/left/right", TreeNode(name="AB"), inplace=False);
    assert resolve_pointer(top, "/left/right").name == "ab";
    assert resolve_pointer(newtop, "/left/right").name == "AB";
    set_pointer(top, "/left/right", TreeNode(name="AB"));
    assert resolve_pointer(top, "/left/right").name == "AB";
}

test "mapping-like object" {
    doc = MockDict(d={"root": {"1": {"2": "3"}}});
    assert resolve_pointer(doc, "/root/1", None) == {"2": "3"};
    assert resolve_pointer(doc, "/root/1/2", None) == "3";
    assert resolve_pointer(doc, "/foo", None) is None;
    assert resolve_pointer(doc, "/x/y/z/d", None) is None;
    assert raises_jpe(lambda -> any { return resolve_pointer(doc, "/foo"); });
    assert raises_jpe(lambda -> any { return resolve_pointer(doc, "/root/1/2/3/4"); });
}

test "escape helpers and pairwise" {
    assert escape("a/b~c") == "a~1b~0c";
    assert unescape("a~1b~0c") == "a/b~c";
    assert unescape("~01") == "~1";
    assert len(list(pairwise([]))) == 0;
    assert len(list(pairwise([1]))) == 0;
    assert list(pairwise([1, 2, 3, 4])) == [(1, 2), (2, 3), (3, 4)];
}
