"""Reference harness: exercises every public function of iss_heliobond__backend__409."""
import importlib

mod = importlib.import_module("iss_heliobond__backend__409")
FlagSet = mod.FlagSet

fs = FlagSet()
fs.load({
    "checkout-v2": {"enabled": True, "rollout_percentage": 100, "depends_on": []},
    "new-tax-api": {"enabled": True, "rollout_percentage": 100, "depends_on": []},
    "one-click": {"enabled": True, "rollout_percentage": 100,
                  "depends_on": ["checkout-v2", "new-tax-api"]},
})

# Happy path: closure gates all pass.
r = fs.evaluate("one-click")
assert r == {"name": "one-click", "value": True, "reason": "ok"}, r
assert fs.evaluate("checkout-v2")["value"] is True

# Unknown flag.
assert fs.evaluate("ghost") == {"name": "ghost", "value": False, "reason": "unknown_flag"}

# Gate failure propagates from the smallest failing flag in the closure.
fs.merge({"new-tax-api": {"enabled": False, "depends_on": []}})
r = fs.evaluate("one-click")
assert r == {"name": "one-click", "value": False, "reason": "gate:new-tax-api"}, r

# Rollout gate uses the caller bucket: 100% blocks bucket 100, not 99.
fs.merge({"new-tax-api": {"enabled": True, "rollout_percentage": 50, "depends_on": []}})
assert fs.evaluate("one-click", {"bucket": 49})["value"] is True
r = fs.evaluate("one-click", {"bucket": 50})
assert r["reason"] == "gate:new-tax-api" and r["value"] is False, r

# Unresolvable dependency: smallest unknown name wins.
fs.merge({"payments": {"enabled": True, "depends_on": ["zeta-svc", "alpha-svc"]}})
r = fs.evaluate("payments")
assert r == {"name": "payments", "value": False, "reason": "unknown_dependency:alpha-svc"}, r

# Two-cycle from the issue: a <-> b crashes the old code; fixed result here.
cyc = FlagSet()
cyc.load({
    "a": {"enabled": True, "rollout_percentage": 100, "depends_on": ["b"]},
    "b": {"enabled": True, "rollout_percentage": 100, "depends_on": ["a"]},
})
assert cyc.evaluate("a") == {"name": "a", "value": False, "reason": "dependency_cycle"}
assert cyc.evaluate("b") == {"name": "b", "value": False, "reason": "dependency_cycle"}

# Three-cycle a -> b -> c -> a.
cyc.merge({"b": {"enabled": True, "depends_on": ["c"]}})
cyc.merge({"c": {"enabled": True, "depends_on": ["a"]}})
assert cyc.evaluate("a") == {"name": "a", "value": False, "reason": "dependency_cycle"}

# Cycle beats gate failure elsewhere in the closure (cycle priority).
cyc2 = FlagSet()
cyc2.load({
    "root": {"enabled": True, "depends_on": ["off", "loop"]},
    "off": {"enabled": False, "depends_on": []},
    "loop": {"enabled": True, "depends_on": ["loopback"]},
    "loopback": {"enabled": True, "depends_on": ["loop"]},
})
assert cyc2.evaluate("root") == {"name": "root", "value": False, "reason": "dependency_cycle"}

# Diamond: per the suggested fix, a flag revisited within one evaluation is a cycle.
dia = FlagSet()
dia.load({
    "root": {"enabled": True, "depends_on": ["l", "r"]},
    "l": {"enabled": True, "depends_on": ["d"]},
    "r": {"enabled": True, "depends_on": ["d"]},
    "d": {"enabled": True, "depends_on": []},
})
assert dia.evaluate("root") == {"name": "root", "value": False, "reason": "dependency_cycle"}

# load() replaces the whole set; stale flags disappear.
fs2 = FlagSet()
fs2.load({"x": {"enabled": True, "depends_on": []}})
fs2.load({"y": {"enabled": True, "depends_on": []}})
assert fs2.evaluate("x")["reason"] == "unknown_flag"
assert fs2.evaluate("y")["value"] is True
