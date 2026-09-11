"""Reference harness for dowdiness/canopy#1236."""

from __future__ import annotations

import iss_dowdiness__canopy__1236 as m


def test_responsibility_ledger() -> None:
    owns = [
        ("shell", "publisher"),
        ("shell", "pkg"),
    ]
    publishes = [
        ("publisher", "proj_a"),
        ("publisher", "proj_b"),
    ]
    got = m.responsibility_ledger("shell", owns, publishes)
    assert got["shell"] == "shell"
    assert got["publisher"] == "shell"
    assert got["pkg"] == "shell"
    assert got["proj_a"] == "publisher"
    assert got["proj_b"] == "publisher"


def test_lifetime_owners() -> None:
    chain = [
        ("root_shell", "mid_shell"),
        ("mid_shell", "leaf_proj"),
    ]
    assert m.lifetime_owners("leaf_proj", chain) == ["mid_shell", "root_shell"]


def test_cut_b_prime_closure() -> None:
    edges = [
        ("build", "compile"),
        ("build", "lint"),
        ("compile", "link"),
        ("lint", "link"),
    ]
    got = m.cut_b_prime_closure("build", edges)
    assert got[0] == "build"
    assert sorted(got) == sorted(["build", "compile", "lint", "link"])
    assert len(got) == len(set(got))


def test_diamond_ledger_once() -> None:
    owns = [
        ("shell", "left"),
        ("shell", "right"),
        ("left", "publisher"),
        ("right", "publisher"),
    ]
    publishes = [("publisher", "proj")]
    got = m.responsibility_ledger("shell", owns, publishes)
    assert got["publisher"] == "shell"
    assert got["proj"] == "publisher"
    assert len(got) == len(set(got.keys()))


def test_diamond_closure_once() -> None:
    edges = [
        ("r", "a"),
        ("r", "b"),
        ("a", "d"),
        ("b", "d"),
    ]
    got = m.cut_b_prime_closure("r", edges)
    assert got.count("d") == 1
    assert sorted(got) == sorted(["r", "a", "b", "d"])


if __name__ == "__main__":
    test_responsibility_ledger()
    test_lifetime_owners()
    test_cut_b_prime_closure()
    test_diamond_ledger_once()
    test_diamond_closure_once()
    print("ok")
