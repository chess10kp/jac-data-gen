import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
MOD = HERE / "iss_lvlup-sw__exarchos__1816.py"

spec = importlib.util.spec_from_file_location("dkg_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

# Supersession chain: cur -> p1 -> p2
CHAIN = [("cur", "p1"), ("p1", "p2")]

# Diamond: adversarial insertion order (revisit before deeper first-visits)
DIAMOND = [("d0", "a"), ("d0", "b"), ("a", "t"), ("b", "t")]

assert mod.transitive_query("cur", CHAIN) == ["cur", "p1", "p2"]
assert mod.dkg_reachable("cur", CHAIN) == ["cur", "p1", "p2"]
assert mod.fold_oracle("cur", CHAIN) is True

diamond = mod.dkg_reachable("d0", DIAMOND)
assert diamond.count("t") == 1
assert diamond == ["a", "b", "d0", "t"]

assert mod.transitive_query("missing", CHAIN) == []
assert mod.dkg_reachable("missing", CHAIN) == []
assert mod.fold_oracle("missing", CHAIN) is True

print("ok")
