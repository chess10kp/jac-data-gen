import from passcheck { check_password, strength }

test "good password has no violations" {
    assert len(check_password("Correct-Horse-9-Battery")) == 0;
    assert strength("Correct-Horse-9-Battery") == "strong";
}

test "each rule fires" {
    assert "too_short" in list(check_password("Ab1!"));
    assert "no_upper" in list(check_password("lowercase-only-123"));
    assert "no_lower" in list(check_password("UPPERCASE-ONLY-123"));
    assert "no_digit" in list(check_password("No-Digits-Here-At-All"));
    assert "no_symbol" in list(check_password("NoSymbolsHere123"));
    assert "repeated_chars" in list(check_password("Paaassword-1234"));
    assert "repeated_chars" not in list(check_password("Paassword-12345"));
}

test "violations come back in rule order" {
    assert list(check_password("aaa")) == ["too_short", "no_upper", "no_digit", "no_symbol", "repeated_chars"];
    assert list(check_password("abc")) == ["too_short", "no_upper", "no_digit", "no_symbol"];
}

test "username rule is case insensitive and length gated" {
    assert "contains_username" in list(check_password("My-ALICE-pass-99", "alice"));
    assert "contains_username" not in list(check_password("My-ALICE-pass-99", "bob"));
    assert "contains_username" not in list(check_password("Xy-pass-word-99", "xy"));
    assert "contains_username" not in list(check_password("My-ALICE-pass-99"));
}

test "strength buckets" {
    assert strength("Abcdefghij1!") == "strong";
    assert strength("abcdefghij1!") == "fair";
    assert strength("abcdefghijk!") == "fair";
    assert strength("abcdefghijkl") == "weak";
    assert strength("") == "weak";
}
