# Hidden tests: derived from python-json-pointer 3.2.0 tests.py and python-json-patch 1.34 tests.py
import copy;
import from pointer { JsonPointer, JsonPointerException, EndOfList, resolve_pointer, set_pointer, escape, unescape }
import from patch { JsonPatch, apply_patch, JsonPatchException, InvalidJsonPatch, JsonPatchConflict, JsonPatchTestFailed }

def raises(f: Callable[[], any], exc: type) -> bool {
    try {
        f();
    } except exc {
        return True;
    }
    return False;
}

glob SPEC_DOC: dict[str, any] = {
    "foo": ["bar", "baz"], "": 0, "a/b": 1, "c%d": 2, "e^f": 3, "g|h": 4,
    "i\\j": 5, "k\"l": 6, " ": 7, "m~n": 8
};

test "pointer spec examples" {
    d = SPEC_DOC;
    assert dict(resolve_pointer(d, "")) == d;
    assert list(resolve_pointer(d, "/foo")) == ["bar", "baz"];
    assert resolve_pointer(d, "/foo/0") == "bar";
    assert resolve_pointer(d, "/") == 0;
    assert resolve_pointer(d, "/a~1b") == 1;
    assert resolve_pointer(d, "/c%d") == 2;
    assert resolve_pointer(d, "/i\\j") == 5;
    assert resolve_pointer(d, "/k\"l") == 6;
    assert resolve_pointer(d, "/ ") == 7;
    assert resolve_pointer(d, "/m~0n") == 8;
}

test "pointer end of list and errors" {
    d = {"foo": ["bar", "baz"]};
    assert isinstance(resolve_pointer(d, "/foo/-"), EndOfList);
    assert raises(lambda -> any { return resolve_pointer(d, "/foo/-/1"); }, JsonPointerException);
    assert raises(lambda -> any { return resolve_pointer(d, "/foo/01"); }, JsonPointerException);
    assert raises(lambda -> any { return resolve_pointer(d, "/foo/5"); }, JsonPointerException);
    assert raises(lambda -> any { return resolve_pointer(d, "/nope"); }, JsonPointerException);
    assert raises(lambda -> any { return JsonPointer("foo"); }, JsonPointerException);
    assert raises(lambda -> any { return JsonPointer("/foo~2"); }, JsonPointerException);
    assert resolve_pointer(d, "/nope", None) is None;
    assert resolve_pointer(d, "/foo/9", "dflt") == "dflt";
}

test "pointer parts and round trip" {
    cases = [("", 0), ("/foo", 1), ("/foo/0", 2), ("/", 1), ("/a~1b", 1), ("/m~0n", 1), ("/î", 1)];
    for (path, n) in cases {
        ptr = JsonPointer(path);
        assert str(ptr) == path;
        assert len(ptr.get_parts()) == n;
        assert JsonPointer.from_parts(ptr.parts) == ptr;
    }
    assert list(JsonPointer("/a~1b/m~0n/0").parts) == ["a/b", "m~n", "0"];
    assert str(JsonPointer.from_parts(["a", "~", "/", 0])) == "/a/~0/~1/0";
    assert escape("a/b~c") == "a~1b~0c";
    assert unescape("a~1b~0c") == "a/b~c";
    assert unescape("~01") == "~1";
}

test "pointer equality, hash, contains, join" {
    p1 = JsonPointer("/something/1/b");
    p2 = JsonPointer("/something/1/b");
    p3 = JsonPointer("/something/1.0/b");
    assert p1 == p2 and not (p1 == p3);
    assert hash(p1) == hash(p2) and hash(p1) != hash(p3);
    assert not (p1 == "/something/1/b");
    a = JsonPointer("/a/b/c");
    b = JsonPointer("/a/b");
    c = JsonPointer("/b/c");
    assert a.contains(b) and a.contains(a) and not a.contains(c);
    assert b in a and not (c in a);
    assert str(a.join(b)) == "/a/b/c/a/b";
    assert str(a.join(["a"])) == "/a/b/c/a";
    assert str(a.join("/a/b")) == "/a/b/c/a/b";
    assert raises(lambda -> any { return a.join(0); }, JsonPointerException);
}

test "pointer set" {
    doc = {"foo": {"anArray": [{"prop": 44}], "another prop": {"baz": "A string"}}};
    out = set_pointer(doc, "/foo/anArray/0/prop", 55);
    assert out["foo"]["anArray"][0]["prop"] == 55;
    assert doc["foo"]["anArray"][0]["prop"] == 55;
    set_pointer(doc, "/foo/yet another prop", "added prop");
    assert doc["foo"]["yet another prop"] == "added prop";
    other = set_pointer(doc, "/foo/anArray/-", 7, False);
    assert len(other["foo"]["anArray"]) == 2 and len(doc["foo"]["anArray"]) == 1;
    assert raises(lambda -> any { return set_pointer(doc, "", 1); }, JsonPointerException);
    assert set_pointer(doc, "", 1, False) == 1;
    assert raises(lambda -> any { return set_pointer({"s": "abc"}, "/s/0", "x"); }, JsonPointerException);
    assert raises(lambda -> any { return set_pointer({"l": [1]}, "/l/5", "x"); }, JsonPointerException);
}

test "patch add / remove / replace" {
    docx = {"foo": "bar"};
    res = apply_patch(docx, [{"op": "add", "path": "/baz", "value": "qux"}]);
    assert res is not docx and res["baz"] == "qux" and "baz" not in docx;
    same = apply_patch(docx, [{"op": "add", "path": "/baz", "value": "qux"}], in_place=True);
    assert same is docx and docx["baz"] == "qux";
    assert list(apply_patch({"foo": ["bar", "baz"]}, [{"op": "add", "path": "/foo/1", "value": "qux"}])["foo"]) == ["bar", "qux", "baz"];
    assert "baz" not in apply_patch({"foo": "bar", "baz": "qux"}, [{"op": "remove", "path": "/baz"}]);
    assert list(apply_patch({"foo": ["bar", "qux", "baz"]}, [{"op": "remove", "path": "/foo/1"}])["foo"]) == ["bar", "baz"];
    assert apply_patch({"foo": "bar", "baz": "qux"}, [{"op": "replace", "path": "/baz", "value": "boo"}])["baz"] == "boo";
    assert list(apply_patch({"foo": ["bar", "qux", "baz"]}, [{"op": "replace", "path": "/foo/1", "value": "boo"}])["foo"]) == ["bar", "boo", "baz"];
    assert list(apply_patch({"foo": [1]}, [{"op": "add", "path": "/foo/1", "value": 2}])["foo"]) == [1, 2];
    assert list(apply_patch({"foo": [1, 2]}, [{"op": "add", "path": "/foo/-", "value": 3}, {"op": "add", "path": "/foo/-", "value": 4}])["foo"]) == [1, 2, 3, 4];
    assert raises(lambda -> any { return apply_patch({"foo": ["bar"]}, [{"op": "remove", "path": "/foo/-"}]); }, JsonPointerException);
}

test "patch whole document" {
    assert dict(apply_patch({"foo": "bar"}, [{"op": "replace", "path": "", "value": {"baz": "qux"}}])) == {"baz": "qux"};
    assert dict(apply_patch({"foo": "bar"}, [{"op": "add", "path": "", "value": {"baz": "qux"}}])) == {"baz": "qux"};
    assert dict(apply_patch(["foo", "bar"], [{"op": "add", "path": "", "value": {"baz": "qux"}}])) == {"baz": "qux"};
    assert apply_patch(["foo", "bar"], [{"op": "move", "from": "/0", "path": ""}]) == "foo";
    assert apply_patch(["foo", "bar"], [{"op": "copy", "from": "/1", "path": ""}]) == "bar";
    for op in ["add", "replace"] {
        value = {"foo": [1]};
        res = apply_patch({}, [{"op": op, "path": "", "value": value}]);
        res["foo"].append(2);
        assert len(value["foo"]) == 1;
    }
}

test "patch does not modify the patch document" {
    ops = [
        {"op": "add", "path": "/foo", "value": "bar"},
        {"op": "add", "path": "/baz", "value": [1, 2, 3]},
        {"op": "remove", "path": "/baz/1"},
        {"op": "test", "path": "/baz", "value": [1, 3]},
        {"op": "replace", "path": "/baz/0", "value": 42},
        {"op": "remove", "path": "/baz/1"}
    ];
    expected = copy.deepcopy(ops);
    p = JsonPatch(patch=ops);
    assert dict(p.apply({})) == {"foo": "bar", "baz": [42]};
    assert p.patch == expected;
    assert dict(p.apply({})) == {"foo": "bar", "baz": [42]};
    p2 = JsonPatch(patch=[{"op": "add", "path": "/foo", "value": {"bar": [1]}}]);
    doc = {"baz": None};
    p2.apply(doc, in_place=True);
    doc["foo"]["bar"].append(3);
    assert len(p2.patch[0]["value"]["bar"]) == 1;
    assert bool(p) and not bool(JsonPatch(patch=[]));
}

test "patch move and copy" {
    docx = {"foo": {"bar": "baz", "waldo": "fred"}, "qux": {"corge": "grault"}};
    moved = apply_patch(docx, [{"op": "move", "from": "/foo/waldo", "path": "/qux/thud"}]);
    assert dict(moved) == {"qux": {"thud": "fred", "corge": "grault"}, "foo": {"bar": "baz"}};
    copied = apply_patch(docx, [{"op": "copy", "from": "/foo/waldo", "path": "/qux/thud"}]);
    assert dict(copied) == {"qux": {"thud": "fred", "corge": "grault"}, "foo": {"bar": "baz", "waldo": "fred"}};
    assert list(apply_patch({"foo": ["all", "grass", "cows", "eat"]}, [{"op": "move", "from": "/foo/1", "path": "/foo/3"}])["foo"]) == ["all", "cows", "eat", "grass"];
    assert list(apply_patch({"foo": ["all", "grass", "cows", "eat"]}, [{"op": "copy", "from": "/foo/1", "path": "/foo/3"}])["foo"]) == ["all", "grass", "cows", "grass", "eat"];
    assert list(apply_patch([{"foo": []}, {"bar": []}], [{"op": "move", "from": "/0", "path": "/0/bar/0"}])) == [{"bar": [{"foo": []}]}];
    res = apply_patch({"foo": [{"bar": 42}, {"baz": 3.14}], "boo": []}, [{"op": "copy", "from": "/foo/0", "path": "/boo/0"}]);
    res = apply_patch(res, [{"op": "add", "path": "/foo/0/zoo", "value": 255}]);
    assert list(res["boo"]) == [{"bar": 42}];
    snap = apply_patch({"foo": [1]}, [{"op": "copy", "from": "", "path": "/snapshot"}]);
    snap["foo"].append(2);
    assert list(snap["snapshot"]["foo"]) == [1];
    assert raises(lambda -> any { return apply_patch(docx, [{"op": "move", "from": "/foo/non-existent", "path": "/qux/thud"}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch(docx, [{"op": "copy", "from": "/foo/non-existent", "path": "/qux/thud"}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch({"foo": {"bar": {"baz": 1}}}, [{"op": "move", "from": "/foo", "path": "/foo/bar"}]); }, JsonPatchException);
}

test "patch test operation" {
    docx = {"baz": "qux", "foo": ["a", 2, "c"]};
    apply_patch(docx, [{"op": "test", "path": "/baz", "value": "qux"}, {"op": "test", "path": "/foo/1", "value": 2}]);
    apply_patch({"baz": 1}, [{"op": "test", "path": "", "value": {"baz": 1}}]);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, [{"op": "test", "path": "/bar", "value": "bar"}]); }, JsonPatchTestFailed);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, [{"op": "test", "path": "/baz", "value": "bar"}]); }, JsonPatchTestFailed);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, [{"op": "test", "path": "/bar"}]); }, InvalidJsonPatch);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, [{"op": "test", "path": "/baz"}]); }, JsonPatchTestFailed);
    assert raises(lambda -> any { return apply_patch({"bar": {"qux": 2}}, [{"op": "test", "path": "/baz/qx"}]); }, JsonPatchTestFailed);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, [{"op": "test", "path": "/bar", "value": "bar"}]); }, AssertionError);
}

test "patch invalid input" {
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, {"op": "test", "path": "/bar"}); }, InvalidJsonPatch);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, [{"op": "test", "value": "bar"}]); }, InvalidJsonPatch);
    assert raises(lambda -> any { return apply_patch({"bar": "qux"}, "[{\"op\": \"add\", \"path\": null, \"value\": \"bar\"}]"); }, InvalidJsonPatch);
    assert raises(lambda -> any { return apply_patch({"foo": "bar"}, [{"path": "/child", "value": {}}]); }, JsonPatchException);
    assert raises(lambda -> any { return apply_patch({"foo": "bar"}, [{"op": "invalid", "path": "/child", "value": {}}]); }, JsonPatchException);
    res = apply_patch({"foo": "bar"}, "[{\"op\": \"add\", \"path\": \"/baz\", \"value\": \"qux\"}]");
    assert res["baz"] == "qux";
    assert apply_patch({"foo": "bar", "baz": "qux"}, [{"op": "replace", "path": "/baz", "value": "boo", "foo": "ignore"}])["baz"] == "boo";
}

test "patch conflicts" {
    assert raises(lambda -> any { return apply_patch({"foo": [1, 2]}, [{"op": "remove", "path": "/foo/10"}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch({"foo": [1, 2]}, [{"op": "remove", "path": "/foo/b"}]); }, JsonPointerException);
    assert raises(lambda -> any { return apply_patch({"foo": {"bar": "barz"}}, [{"op": "remove", "path": "/foo/non-existent"}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch({"foo": [1, 2]}, [{"op": "add", "path": "/foo/10", "value": 1}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch({"foo": [1, 2]}, [{"op": "replace", "path": "/foo/10", "value": 10}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch({"foo": [0, 1]}, [{"op": "replace", "path": "/foo/2", "value": 2}]); }, JsonPatchConflict);
    assert raises(lambda -> any { return apply_patch({"foo": 1}, [{"op": "replace", "path": "/bar", "value": 10}]); }, JsonPatchConflict);
}

test "patch never indexes into strings" {
    src = {"foo": "should-not-be-indexable"};
    assert raises(lambda -> any { return apply_patch(src, [{"op": "test", "path": "/foo/0", "value": "s"}]); }, JsonPatchTestFailed);
    assert raises(lambda -> any { return apply_patch(src, [{"op": "copy", "from": "/foo/0", "path": "/bar"}]); }, JsonPointerException);
    assert raises(lambda -> any { return apply_patch(src, [{"op": "move", "from": "/foo/0", "path": "/bar"}]); }, JsonPointerException);
    assert raises(lambda -> any { return apply_patch(src, [{"op": "remove", "path": "/foo/0"}]); }, JsonPointerException);
    assert raises(lambda -> any { return apply_patch(src, [{"op": "add", "path": "/foo/0", "value": "x"}]); }, JsonPointerException);
}
