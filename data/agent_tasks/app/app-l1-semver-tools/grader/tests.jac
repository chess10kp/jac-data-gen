import from semver { Version, parse_version, compare, bump, max_satisfying }

test "parse plain, v-prefixed and pre-release" {
    a = parse_version("1.2.3");
    assert a.major == 1 and a.minor == 2 and a.patch == 3 and a.pre == "";
    b = parse_version("v10.0.7");
    assert b.major == 10 and b.patch == 7;
    c = parse_version("2.0.0-beta.2");
    assert c.pre == "beta.2" and c.major == 2;
}

test "parse rejects garbage" {
    for bad in ["1.2", "1.2.3.4", "a.b.c", "1.2.x", "1.2.3-", ""] {
        try {
            parse_version(bad);
            assert False, "expected ValueError";
        } except ValueError {
            assert True;
        }
    }
}

test "compare numeric fields" {
    assert compare("1.2.3", "1.2.3") == 0;
    assert compare("1.10.0", "1.9.9") == 1;
    assert compare("0.9.0", "1.0.0") == -1;
    assert compare("v2.0.0", "2.0.0") == 0;
}

test "compare pre-release precedence" {
    chain = ["1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta", "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0"];
    for i in range(len(chain) - 1) {
        assert compare(chain[i], chain[i + 1]) == -1, f"{chain[i]} < {chain[i + 1]}";
        assert compare(chain[i + 1], chain[i]) == 1, f"{chain[i + 1]} > {chain[i]}";
    }
}

test "bump" {
    assert bump("1.2.3", "patch") == "1.2.4";
    assert bump("1.2.3", "minor") == "1.3.0";
    assert bump("v1.2.3", "major") == "2.0.0";
    assert bump("1.2.3-rc.1", "patch") == "1.2.3";
    assert bump("1.2.3-rc.1", "minor") == "1.3.0";
    try {
        bump("1.2.3", "build");
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "max satisfying caret range" {
    vs = ["1.3.9", "1.4.0", "1.12.1", "2.0.0", "1.13.0-beta", "1.4.5", "0.9.0"];
    assert max_satisfying(vs, "^1.4.0") == "1.12.1";
    assert max_satisfying(vs, "^2.0.0") == "2.0.0";
    assert max_satisfying(vs, "^3.0.0") is None;
    assert max_satisfying(["1.0.0", "1.1.0"], "^1.2.0") is None;
}
