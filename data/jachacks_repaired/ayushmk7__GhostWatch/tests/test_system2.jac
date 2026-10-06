# tests/test_system2.jac — Deterministic System 2 + shared tests (no live GitHub/Discord/E2B).

import hmac;
import from hashlib { sha256 }
import from integrations.github { validate_webhook_signature }
import from lib.manifest {
    normalize_package_name,
    dedupe_incident_key,
    parse_manifest_deps,
    manifest_delta,
    classify_dependency_risks,
    fix_invert_manifest,
    rank_gap_candidates,
    package_alias_map,
    impl_likely_has_conventional_test
}
import from lib.sandbox_exec { pip_requirements_file_line }
import from lib.issue_intel {
    issues_fingerprint_from_list,
    issue_digest_cache_fresh,
    issues_fetch_cache_fresh
}
import from lib.repo_demo_env { ghostwatch_demo_repo_url, ghostwatch_demo_repo_slug }

test "normalize_package_name collapses separators" {
    assert normalize_package_name("Foo_Bar.baz") == "foo-bar-baz";
}

test "dedupe_incident_key is stable" {
    k1 = dedupe_incident_key("o/r", "abc", "package.json", "Left-Pad");
    k2 = dedupe_incident_key("o/r", "abc", "package.json", "left_pad");
    assert k1 == k2;
}

test "parse_manifest_deps reads package.json" {
    j = '{"dependencies":{"a":"^1.0.0","b":"2.x"}}';
    d = parse_manifest_deps("package.json", j);
    assert d.get("a", "") == "^1.0.0";
}

test "manifest_delta detects added keys" {
    p = {"x": "1"};
    c = {"x": "1", "y": "2"};
    delta = manifest_delta(p, c);
    added = delta.get("added", {});
    assert "y" in added;
}

test "classify_dependency_risks flags phantom import" {
    added = {"evil-pkg": "1.0.0"};
    graph = set(["requests"]);
    risks = classify_dependency_risks("requirements.txt", "", "", added, graph);
    assert len(risks) > 0;
}

test "pip_requirements_file_line keeps full requirements.txt line" {
    assert pip_requirements_file_line("requests", "requests>=2.0") == "requests>=2.0";
    assert pip_requirements_file_line("foo", "") == "foo";
}

test "fix_invert_manifest requirements matches names case-insensitively" {
    par = "requests==1\n";
    cur = "Requests==9\n";
    out = fix_invert_manifest("requirements.txt", par, cur, "requests");
    assert "==1" in out;
    assert "==9" not in out;
}

test "fix_invert_manifest removes added npm dep" {
    par = '{"dependencies":{"a":"1"}}';
    cur = '{"dependencies":{"a":"1","b":"9"}}';
    out = fix_invert_manifest("package.json", par, cur, "b");
    assert "b" not in out or "\"b\"" not in out;
}

test "rank_gap_candidates prefers untested core files" {
    files = ["walkers/foo.jac", "tests/test_foo.jac", "README.md"];
    ranked = rank_gap_candidates(files, set(), set(), ["walkers/"]);
    assert len(ranked) > 0;
}

test "impl_likely_has_conventional_test matches test_<stem> files" {
    assert impl_likely_has_conventional_test(
        "walkers/foo.jac",
        {"tests/test_foo.jac"}
    );
    assert not impl_likely_has_conventional_test(
        "walkers/bar.jac",
        {"tests/test_foo.jac"}
    );
}

test "rank_gap_candidates lowers missing-test weight when conventional test exists" {
    files = ["walkers/foo.jac", "tests/test_foo.jac"];
    without = rank_gap_candidates(files, set(), set(), ["walkers/"]);
    with_tests = rank_gap_candidates(files, {"tests/test_foo.jac"}, set(), ["walkers/"]);
    assert len(without) > 0 and len(with_tests) > 0;
    assert int(without[0].get("score", 0)) > int(with_tests[0].get("score", 0));
}

test "package_alias_map contains pillow alias" {
    m = package_alias_map();
    assert m.get("pil", "") == "pillow";
}

test "HMAC validation accepts correct signature" {
    payload = bytes("test_payload", "utf-8");
    secret = "my_secret";
    correct_sig = "sha256=" + hmac.new(secret.encode(), payload, sha256).hexdigest();
    assert validate_webhook_signature(payload, correct_sig, secret);
}

test "HMAC validation rejects wrong signature" {
    payload = bytes("test_payload", "utf-8");
    assert not validate_webhook_signature(payload, "sha256=deadbeef", "my_secret");
}

test "ghostwatch demo repo url is fixed to jaseci" {
    assert ghostwatch_demo_repo_url() == "https://github.com/ayushmk7/GhostWatch";
    assert ghostwatch_demo_repo_slug("https://github.com/ayushmk7/GhostWatch") == "ayushmk7/GhostWatch";
}

test "issues_fingerprint_from_list is stable for identical input" {
    x = [{"number": 1, "updated_at": "a"}, {"number": 2, "updated_at": "b"}];
    assert issues_fingerprint_from_list(x) == issues_fingerprint_from_list(x);
}

test "issue_digest_cache_fresh respects ttl" {
    assert issue_digest_cache_fresh("1000", 1005, 10);
    assert not issue_digest_cache_fresh("1000", 1020, 10);
}

test "issues_fetch_cache_fresh respects ttl" {
    assert issues_fetch_cache_fresh("2000", 2005, 90);
    assert not issues_fetch_cache_fresh("2000", 2100, 90);
}
