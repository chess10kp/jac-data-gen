"""Guard tests for iss_Kinetic639__coreframe-boilerplate__95.jac"""

import from iss_Kinetic639__coreframe-boilerplate__95 { CategoryTree }

def _tree() -> CategoryTree {
    t = CategoryTree();
    for c in ["root", "electronics", "phones", "android", "ios"] {
        t.add_category(c);
    }
    t.add_child("root", "electronics");
    t.add_child("electronics", "phones");
    t.add_child("phones", "android");
    t.add_child("phones", "ios");
    return t;
}

def _diamond() -> CategoryTree {
    t = CategoryTree();
    for c in ["top", "left", "right", "join"] {
        t.add_category(c);
    }
    t.add_child("top", "left");
    t.add_child("top", "right");
    t.add_child("left", "join");
    t.add_child("right", "join");
    return t;
}

def _cycle() -> CategoryTree {
    t = CategoryTree();
    for c in ["a", "b", "c"] {
        t.add_category(c);
    }
    t.add_child("a", "b");
    t.add_child("b", "c");
    t.add_child("c", "a");
    return t;
}

test "descendants and ancestors" {
    t = _tree();
    assert t.find_cycle() == [];
    assert t.descendants("phones") == ["android", "ios", "phones"];
    assert t.ancestors("android") == ["electronics", "phones", "root"];
}

test "diamond adversarial closure" {
    t = _diamond();
    assert t.find_cycle() == [];
    assert t.descendants("top") == ["join", "left", "right", "top"];
}

test "cycle multiset" {
    t = _cycle();
    cyc = t.find_cycle();
    assert len(cyc) >= 2;
    assert sorted(set(cyc)) == ["a", "b", "c"];
}

test "unknown KeyError" {
    t = _tree();
    try {
        t.add_child("nope", "root");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}
