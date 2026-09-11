"""Reference harness for iss_tokio-rs__toasty__420."""
import importlib.util, pathlib
spec = importlib.util.spec_from_file_location("mod", pathlib.Path(__file__).with_name("iss_tokio-rs__toasty__420.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
build_graph=mod.build_graph; reachable=mod.reachable; has_cycle=mod.has_cycle; downstream=mod.downstream

def main():
    g=build_graph(["a","b","c","d"], [("a","b"),("b","c"),("a","c"),("c","d")])
    assert reachable(g,"a")==["b","c","d"]
    assert has_cycle(g)==False
    diamond=build_graph(["top","left","right","join"], [("top","left"),("top","right"),("left","join"),("right","join")])
    assert reachable(diamond,"top")==["join","left","right"]
    assert downstream(diamond,["top"])==["join","left","right"]
    cyc=build_graph(["a","b","c"], [("a","b"),("b","c"),("c","a")])
    assert has_cycle(cyc)==True
    assert reachable(cyc,"a")==["b","c"]
    adv=build_graph(["r","a","b","c","d"], [("r","b"),("r","a"),("a","c"),("b","c"),("c","d")])
    assert sorted(reachable(adv,"r"))==["a","b","c","d"]
    assert downstream(g,["ghost","a"])==["b","c","d"]
    print("ref OK")
if __name__=="__main__": main()
