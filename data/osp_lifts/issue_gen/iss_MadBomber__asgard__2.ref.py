import importlib.util, pathlib
HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("as2", HERE / "iss_MadBomber__asgard__2.py")
mod = importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(mod)
load_dag, parallel_waves, has_cycle = mod.load_dag, mod.parallel_waves, mod.has_cycle

def main():
    g = load_dag(["a","b","c","d"], [("a","c"),("b","c"),("c","d")])
    assert has_cycle(g) is False
    assert parallel_waves(g) == [["a","b"],["c"],["d"]]
    cyc = load_dag(["x","y"], [("x","y"),("y","x")])
    assert has_cycle(cyc) is True
    assert parallel_waves(cyc) is None
    print("ok")
if __name__ == "__main__": main()
