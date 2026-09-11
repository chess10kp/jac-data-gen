#!/usr/bin/env python3
import importlib.util, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_Harborline-Software__shipyard__3090.py"
spec = importlib.util.spec_from_file_location("hull_mod", MOD)
mod = importlib.util.module_from_spec(spec); assert spec.loader
sys.modules["hull_mod"] = mod; spec.loader.exec_module(mod)

def main() -> None:
    h = mod.build_hull()
    h.add_part("keel", "Keel", 10)
    h.add_part("frame", "Frame", 5, "keel")
    h.add_part("deck", "Deck", 3, "frame")
    h.add_part("mast", "Mast", 7, "deck")
    assert h.aggregate_subtree("keel") == (25, 4)
    assert sorted(h.descendants("keel")) == ["deck", "frame", "keel", "mast"]
    assert h.ancestors("mast") == ["deck", "frame", "keel"]
    assert h.aggregate_subtree("missing") == (0, 0)
    try:
        h.add_part("orphan", parent_id="nope")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass
    # adversarial diamond + back-edge insertion order
    d = mod.build_hull()
    for pid, lbl, w, par in [
        ("hull", "H", 1, None), ("port", "P", 2, "hull"),
        ("stbd", "S", 2, "hull"), ("bow", "B", 4, "port"),
    ]:
        d.add_part(pid, lbl, w, par)
    d._children.setdefault("stbd", []).append("bow")  # diamond
    d._children["bow"].append("hull")  # cycle for revisit stress
    assert sorted(d.descendants("hull")) == ["bow", "hull", "port", "stbd"]
    print("ok")

if __name__ == "__main__":
    main()
