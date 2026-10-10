import from passcheck { check_password, strength }

test "a compliant password has no issues" {
    assert len(check_password("Tr0ub4dor&Three")) == 0;
}

test "length boundary is twelve" {
    assert "too_short" in check_password("Abcdefgh1!x");
    assert "too_short" not in check_password("Abcdefgh1!xy");
}

test "character class rules" {
    assert list(check_password("abcdefgh1!xy")) == ["no_upper"];
    assert list(check_password("ABCDEFGH1!XY")) == ["no_lower"];
    assert list(check_password("Abcdefghi!xy")) == ["no_digit"];
    assert list(check_password("Abcdefgh12xy")) == ["no_symbol"];
}

test "space counts as a symbol" {
    assert "no_symbol" not in check_password("Abcdefgh 1xy");
}

test "username rule needs three characters and ignores case" {
    assert list(check_password("Xx-JOHNNY-99!", "johnny")) == ["contains_username"];
    assert "contains_username" not in check_password("Xx-JOHNNY-99!", "jo");
    assert "contains_username" in check_password("Xx-JOHNNY-99!", "joh");
    assert "contains_username" not in check_password("Xx-JOHNNY-99!", "mary");
    assert "contains_username" not in check_password("Xx-JOHNNY-99!");
}

test "three identical characters in a row" {
    assert list(check_password("Abcdefg111!x")) == ["repeated_chars"];
    assert len(check_password("Abcdefg11!1x")) == 0;
    assert list(check_password("Abcdefg1!zzz")) == ["repeated_chars"];
    assert list(check_password("Abcdefg1!xxxx")) == ["repeated_chars"];
}

test "violations are listed in rule order" {
    assert list(check_password("")) == ["too_short", "no_upper", "no_lower", "no_digit", "no_symbol"];
    assert list(check_password("bbb", "bbb")) == ["too_short", "no_upper", "no_digit", "no_symbol", "contains_username", "repeated_chars"];
}

test "strength buckets" {
    assert strength("Tr0ub4dor&Three") == "strong";
    assert strength("tr0ub4dor&three") == "fair";
    assert strength("tr0ub4dor&") == "fair";
    assert strength("troubadorthree") == "weak";
    assert strength("aaa") == "weak";
}
