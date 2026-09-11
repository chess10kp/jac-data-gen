"""Guard: openclaw/openclaw#76611."""
# (same candidate as .jac above — paste full .jac body, then append:)

test "dirty flush outside walk" {
    g = load_crypto_store([("root", ["sess"]), ("sess", ["key"])]);
    mark_dirty(g, "key");
    assert pending_persist(g) == ["key", "root", "sess"];
    assert flush_dirty(g) == ["key", "root", "sess"];
    assert pending_persist(g) == [];
}

test "diamond adversarial reach" {
    g = load_crypto_store(
        [("hub", ["a", "b"]), ("a", ["leaf"]), ("b", ["leaf"]), ("leaf", [])],
    );
    mark_dirty(g, "leaf");
    assert reachable_keys(g, "hub") == ["a", "b", "hub", "leaf"];
    assert flush_dirty(g) == ["leaf"];
}
