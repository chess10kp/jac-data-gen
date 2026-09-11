"""Reference harness for markmhendrickson/neotoma#1969."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "neo1969", HERE / "iss_markmhendrickson__neotoma__1969.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["neo1969"] = mod
spec.loader.exec_module(mod)

load_graph = mod.load_graph
knows_of = mod.knows_of
find_paths = mod.find_paths
MAX_PATH_DEPTH = mod.MAX_PATH_DEPTH


def _main_fixture():
    entities = [
        ("alice", "contact"),
        ("bob", "contact"),
        ("carol", "contact"),
        ("dana", "contact"),
        ("eric", "contact"),
        ("acme", "company"),
        ("beta", "company"),
        ("sequoia", "fund"),
    ]
    knows = [
        ("alice", "bob"),
        ("bob", "carol"),
        ("alice", "dana"),
        ("carol", "eric"),
    ]
    works_at = [
        ("carol", "acme"),
        ("dana", "acme"),
        ("eric", "beta"),
    ]
    invested_in = [("sequoia", "beta")]
    return load_graph(entities, knows, works_at, invested_in)


def main() -> None:
    g = _main_fixture()

    assert MAX_PATH_DEPTH == 4
    assert knows_of(g, "alice") == ["bob", "dana"]
    assert knows_of(g, "ghost") == []

    assert find_paths(g, "alice", "acme") == [
        ["alice", "bob", "carol"],
        ["alice", "dana"],
    ]
    assert find_paths(g, "alice", "sequoia") == [
        ["alice", "bob", "carol", "eric"],
    ]
    assert find_paths(g, "dana", "acme") == [["dana"]]
    assert find_paths(g, "ghost", "acme") == []
    assert find_paths(g, "alice", "ghost") == []

    # adversarial KNOWS insertion order (shared bridge before deeper first-visits)
    g2 = load_graph(
        [
            ("s", "contact"),
            ("m1", "contact"),
            ("m2", "contact"),
            ("t", "contact"),
            ("co", "company"),
        ],
        [("s", "m2"), ("m2", "t"), ("s", "m1"), ("m1", "t"), ("m2", "m1")],
        [("t", "co")],
        [],
    )
    assert find_paths(g2, "s", "co") == [
        ["s", "m1", "t"],
        ["s", "m2", "m1", "t"],
        ["s", "m2", "t"],
    ]

    # cyclic KNOWS must terminate
    g3 = load_graph(
        [("a", "contact"), ("b", "contact"), ("c", "contact"), ("co", "company")],
        [("a", "b"), ("b", "c"), ("c", "a")],
        [("c", "co")],
        [],
    )
    assert find_paths(g3, "a", "co", max_depth=10) == [["a", "b", "c"]]

    print("ok")


if __name__ == "__main__":
    main()
