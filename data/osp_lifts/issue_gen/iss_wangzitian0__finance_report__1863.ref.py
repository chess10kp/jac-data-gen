"""Reference harness for iss_wangzitian0__finance_report__1863."""
import importlib.util, pathlib
spec = importlib.util.spec_from_file_location("mod", pathlib.Path(__file__).with_name("iss_wangzitian0__finance_report__1863.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
build_graph = mod.build_graph
reachable = mod.reachable
has_cycle = mod.has_cycle
downstream = mod.downstream

def main():
    g = build_graph(["a","b","c","d"], [("a","b"),("b","c"),("a","c"),("c","d")])
    assert reachable(g, "a") == ["b","c","d"]
    assert reachable(g, "b") == ["c","d"]
    assert reachable(g, "ghost") == []
    assert has_cycle(g) == False
    # diamond: a->b->d, a->c->d should still be single visits
    diamond = build_graph(["top","left","right","join"], [("top","left"),("top","right"),("left","join"),("right","join")])
    assert reachable(diamond, "top") == ["join","left","right"]
    assert downstream(diamond, ["top"]) == ["join","left","right"]
    assert downstream(diamond, ["left","right"]) == ["join"]
    # cycle
    cyc = build_graph(["a","b","c"], [("a","b"),("b","c"),("c","a")])
    assert has_cycle(cyc) == True
    assert reachable(cyc, "a") == ["b","c"]
    assert downstream(cyc, ["a"]) == ["b","c"]
    # adversarial order: insertion order that forces revisit before deep visit
    adv = build_graph(["r","a","b","c","d"], [("r","b"),("r","a"),("a","c"),("b","c"),("c","d")])
    assert sorted(reachable(adv, "r")) == ["a","b","c","d"]
    assert has_cycle(adv) == False
    # downstream with unknown seeds ignored
    assert downstream(g, ["ghost","a"]) == ["b","c","d"]
    print("ref OK")

if __name__ == "__main__":
    main()
