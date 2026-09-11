"""Harness: exercise ConfigStore.remove_section, assert post-state, exit 0."""
from rec_27_config_include_detach import ConfigStore


def build():
    """Fixture:

    app -> [defaults, env_overrides]   (both shared with other sections)
    defaults -> [base_limits]
    staging -> defaults  (so defaults is shared: included_by=2)
    base_limits: timeout inherited everywhere
    """
    store = ConfigStore()
    store.add("app", {"debug": "0"})
    store.add("defaults", {"timeout": "30"})
    store.add("env_overrides", {"debug": "1"})
    store.add("base_limits", {"timeout": "10", "retries": "3"})
    store.add("staging", {"host": "stage"})
    for a, b in [("app", "defaults"), ("app", "env_overrides"),
                 ("defaults", "base_limits"), ("staging", "defaults")]:
        assert store.include(a, b)
    return store


def test_shared_base_detached_not_destroyed():
    s = build()
    snaps = s.remove_section("app")
    # app destroyed; defaults shared with staging -> detached only;
    # env_overrides exclusive -> destroyed; the closure stops at the
    # shared boundary, so base_limits stays alive beneath defaults
    assert sorted(snaps) == ["app", "env_overrides"], sorted(snaps)
    assert "app" not in s.live_sections()
    assert s.included_by_count("defaults") == 1     # staging still inherits
    assert "defaults" in s.live_sections()
    assert "base_limits" in s.live_sections()


def test_exclusive_chain_removed_with_snapshot():
    s = build()
    snaps = s.remove_section("staging")
    assert list(snaps) == ["staging"]
    assert snaps["staging"] == {"host": "stage", "timeout": "30"}
    assert "staging" not in s.live_sections()
    assert s.resolve("app") == {"debug": "0", "retries": "3",
                                "timeout": "30"}


def test_unknown_and_stale_includes_tolerated():
    s = build()
    assert s.remove_section("ghost") == {}
    s.sections["app"].includes.append("vanished")   # stale entry
    snaps = s.remove_section("app")
    assert sorted(snaps) == ["app", "env_overrides"]
    assert "vanished" not in s.sections


if __name__ == "__main__":
    test_shared_base_detached_not_destroyed()
    test_exclusive_chain_removed_with_snapshot()
    test_unknown_and_stale_includes_tolerated()
    print("rec_27 ref harness: all assertions passed")
