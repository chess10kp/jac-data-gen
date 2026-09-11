import importlib.util
from pathlib import Path

MOD = Path(__file__).with_name("iss_openai__codex__32684.py")
spec = importlib.util.spec_from_file_location("iss_openai__codex__32684", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)


def build_fixture() -> mod.DirGraph:
    g = mod.DirGraph()
    for nid, name in [
        ("home", "USERPROFILE"),
        ("docs", "Documents"),
        ("tmp", "tmp"),
        ("cache", "cache"),
        ("link", "link"),
    ]:
        g.add_node(nid, name)
    g.add_child("home", "docs")
    g.add_child("home", "tmp")
    g.add_child("tmp", "cache")
    g.add_child("cache", "link")  # adversarial: revisit before deeper first-visits
    g.add_child("link", "tmp")    # cycle tmp -> cache -> link -> tmp
    return g


def main() -> None:
    g = build_fixture()
    assert g.reachable("home") == ["cache", "docs", "home", "link", "tmp"]
    assert g.safe_prune_order("home") == ["docs", "link", "cache", "tmp", "home"]
    assert g.has_cycle_from("home") is True

    acyclic = mod.DirGraph()
    acyclic.add_node("a", "a")
    acyclic.add_node("b", "b")
    acyclic.add_child("a", "b")
    assert acyclic.has_cycle_from("a") is False
    assert acyclic.safe_prune_order("a") == ["b", "a"]


if __name__ == "__main__":
    main()
