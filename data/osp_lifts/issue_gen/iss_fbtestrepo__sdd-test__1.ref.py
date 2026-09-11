"""Reference harness for fbtestrepo/sdd-test#1."""

from iss_fbtestrepo__sdd-test__1 import (
    ancestors,
    build_graph,
    build_order,
    children,
    direct_deps,
    has_cycle,
    path_to,
    transitive_deps,
)


def _specs_main():
    return [
        ("service", "com.service", None, []),
        ("lib", "com.lib", "service", []),
        ("util", "com.util", "service", ["lib"]),
        ("app", "com.app", "service", ["lib", "util"]),
        ("web", "com.web", "app", ["app"]),
    ]


def main() -> None:
    g = build_graph(_specs_main())
    assert direct_deps(g, "app") == ["lib", "util"]
    assert direct_deps(g, "missing") == []
    assert transitive_deps(g, "web") == ["app", "lib", "util"]
    assert transitive_deps(g, "lib") == []
    assert transitive_deps(g, "missing") == []
    assert children(g, "service") == ["app", "lib", "util"]
    assert children(g, "app") == ["web"]
    assert children(g, "missing") == []
    assert ancestors(g, "web") == ["app", "service"]
    assert ancestors(g, "service") == []
    assert ancestors(g, "missing") == []
    assert has_cycle(g) is False
    assert path_to(g, "web", "lib") == ["web", "app", "lib"]
    assert path_to(g, "web", "web") == ["web"]
    assert path_to(g, "web", "missing") is None
    assert path_to(g, "missing", "lib") is None
    assert build_order(g) == ["lib", "service", "util", "app", "web"]

    cyc = build_graph([
        ("a", "p.a", None, ["b"]),
        ("b", "p.b", None, ["c"]),
        ("c", "p.c", None, ["a"]),
    ])
    assert has_cycle(cyc) is True
    assert build_order(cyc) is None

    # adversarial diamond insertion order
    g2 = build_graph([
        ("left", "p.left", None, ["mid"]),
        ("right", "p.right", None, ["mid"]),
        ("top", "p.top", None, ["left", "right"]),
        ("mid", "p.mid", None, ["bot"]),
        ("bot", "p.bot", None, []),
    ])
    assert transitive_deps(g2, "top") == ["bot", "left", "mid", "right"]
    assert path_to(g2, "top", "bot") == ["top", "left", "mid", "bot"]
    assert build_order(g2) == ["bot", "left", "mid", "right", "top"]
    print("ok")


if __name__ == "__main__":
    main()
