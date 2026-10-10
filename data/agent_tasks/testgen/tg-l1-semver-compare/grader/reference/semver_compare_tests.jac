import from semver { compare, cmp_int, cmp_pre, max_satisfying }

test "cmp_int" {
    assert cmp_int(1, 2) == -1;
    assert cmp_int(2, 1) == 1;
    assert cmp_int(3, 3) == 0;
}

test "equal versions" {
    assert compare("1.4.2", "1.4.2") == 0;
    assert compare("v1.4.2", "1.4.2") == 0;
    assert compare("1.4.2-rc.1", "1.4.2-rc.1") == 0;
}

test "major minor patch precedence is numeric" {
    assert compare("2.0.0", "1.99.99") == 1;
    assert compare("1.2.0", "1.10.0") == -1;
    assert compare("1.2.10", "1.2.9") == 1;
    assert compare("0.0.1", "0.0.2") == -1;
}

test "release beats pre-release" {
    assert compare("1.0.0", "1.0.0-rc.9") == 1;
    assert compare("1.0.0-rc.9", "1.0.0") == -1;
    assert compare("1.0.1-alpha", "1.0.0") == 1;
}

test "pre-release identifiers" {
    assert cmp_pre("", "") == 0;
    assert cmp_pre("", "a") == 1;
    assert cmp_pre("a", "") == -1;
    assert cmp_pre("alpha", "beta") == -1;
    assert cmp_pre("beta", "alpha") == 1;
    assert cmp_pre("2", "11") == -1;
    assert cmp_pre("11", "2") == 1;
    assert cmp_pre("1", "alpha") == -1;
    assert cmp_pre("alpha", "1") == 1;
    assert cmp_pre("alpha", "alpha.1") == -1;
    assert cmp_pre("alpha.1", "alpha") == 1;
    assert cmp_pre("alpha.1", "alpha.beta") == -1;
    assert cmp_pre("rc.1.2", "rc.1.10") == -1;
}

test "full precedence chain" {
    chain = ["1.0.0-1", "1.0.0-alpha", "1.0.0-alpha.2", "1.0.0-alpha.10", "1.0.0-alpha.x", "1.0.0-beta", "1.0.0-rc.1", "1.0.0", "1.0.1"];
    for i in range(len(chain)) {
        for j in range(len(chain)) {
            expected = (i > j) - (i < j);
            assert compare(chain[i], chain[j]) == expected, f"{chain[i]} vs {chain[j]}";
        }
    }
}

test "max_satisfying picks the highest in the same major" {
    vs = ["1.2.0", "1.9.3", "1.10.0", "2.0.0", "0.9.9"];
    assert max_satisfying(vs, "^1.2.0") == "1.10.0";
    assert max_satisfying(vs, "^2.0.0") == "2.0.0";
    assert max_satisfying(vs, "^0.1.0") == "0.9.9";
}

test "max_satisfying respects the floor inclusively" {
    vs = ["1.2.0", "1.2.1", "1.1.9"];
    assert max_satisfying(vs, "^1.2.1") == "1.2.1";
    assert max_satisfying(["1.2.0"], "^1.2.0") == "1.2.0";
    assert max_satisfying(["1.1.9"], "^1.2.0") is None;
}

test "max_satisfying ignores pre-releases and handles empty" {
    assert max_satisfying(["1.5.0-rc.1", "1.4.0"], "^1.0.0") == "1.4.0";
    assert max_satisfying(["1.5.0-rc.1"], "^1.0.0") is None;
    assert max_satisfying([], "^1.0.0") is None;
    assert max_satisfying(["3.1.0", "3.0.5"], " ^3.0.0 ") == "3.1.0";
}

test "max_satisfying keeps first among equal versions" {
    assert max_satisfying(["v1.3.0", "1.3.0"], "^1.0.0") == "v1.3.0";
}
