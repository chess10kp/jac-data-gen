"""Reference harness for allanweber/cartogra#113."""

from iss_allanweber__cartogra__113 import BlastRadiusGraph


def _norm(xs: list[str]) -> list[str]:
    return sorted(xs)


def main() -> None:
    g = BlastRadiusGraph()

    # linear chain: api -> worker -> cache
    g.add_dependency("api", "worker")
    g.add_dependency("worker", "cache")
    assert _norm(g.blast_radius("api")) == ["cache", "worker"]
    assert _norm(g.blast_radius("worker")) == ["cache"]
    assert _norm(g.blast_radius("cache")) == []
    assert _norm(g.blast_radius("missing")) == []

    # diamond: hub fans to left/right then merge
    g2 = BlastRadiusGraph()
    g2.add_dependency("hub", "left")
    g2.add_dependency("hub", "right")
    g2.add_dependency("left", "sink")
    g2.add_dependency("right", "sink")
    assert _norm(g2.blast_radius("hub")) == ["left", "right", "sink"]

    # cycle: a->b->c->a plus d off b (revisit before deep first-visit)
    g3 = BlastRadiusGraph()
    g3.add_dependency("a", "b")
    g3.add_dependency("b", "c")
    g3.add_dependency("c", "a")
    g3.add_dependency("b", "d")
    assert _norm(g3.blast_radius("a")) == ["b", "c", "d"]

    # upstream lookup tolerance
    assert _norm(g3.upstream_of("c")) == ["b"]
    assert _norm(g3.upstream_of("nope")) == []

    print("ok")


if __name__ == "__main__":
    main()
