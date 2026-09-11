"""Reference harness for iss_tox-dev__peryx__1343.py"""

from iss_tox_dev__peryx__1343 import IncludeGraph  # adjust import to match filename on disk


def _norm_cycle(c: list[str] | None) -> tuple[str, ...] | None:
    if c is None:
        return None
  # rotate to canonical smallest string
    rotations = [tuple(c[i:] + c[:i]) for i in range(len(c))]
    return min(rotations)


def main() -> None:
    g = IncludeGraph()
    g.add_include("base", "utils")
    g.add_include("utils", "common")
    assert g.includes_of("base") == ["utils"]
    assert g.closure("base") == ["common", "utils"]
    assert g.find_include_cycle() is None

    # adversarial diamond: shared node reachable on two paths before deep first-visit ordering bites
    g2 = IncludeGraph()
    g2.add_include("a", "shared")
    g2.add_include("b", "shared")
    g2.add_include("shared", "deep")
    g2.add_include("a", "deep")
    assert g2.closure("a") == ["deep", "shared"]
    assert g2.closure("b") == ["deep", "shared"]

    # cycle: a -> b -> c -> a
    g3 = IncludeGraph()
    g3.add_include("a", "b")
    g3.add_include("b", "c")
    g3.add_include("c", "a")
    cyc = _norm_cycle(g3.find_include_cycle())
    assert cyc is not None
    assert set(cyc[:-1]) == {"a", "b", "c"}

    # unknown alias tolerance
    assert g3.includes_of("missing") == []
    assert g3.closure("missing") == []


if __name__ == "__main__":
    main()
