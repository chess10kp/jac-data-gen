"""Reference harness: exercises every public function of iss_asielen__plaintext-family-history__115."""
import importlib

mod = importlib.import_module("iss_asielen__plaintext-family-history__115")
ancestors_within = mod.ancestors_within
apex_ancestor_depth = mod.apex_ancestor_depth
descendant_fan = mod.descendant_fan
in_laws = mod.in_laws
load_family = mod.load_family

fam = load_family(
    ["gm", "gp", "f", "m", "u", "a", "me"],
    [
        ("parent", "f", "gm"), ("parent", "f", "gp"),
        ("parent", "u", "gm"), ("parent", "u", "gp"),
        ("parent", "me", "f"), ("parent", "me", "m"),
        ("spouse", "f", "m"), ("spouse", "u", "a"),
    ],
)
# Pedigree ancestry, generation-bounded; shared ancestors appear once.
assert ancestors_within(fam, "me", 1) == ["f", "m"]
assert ancestors_within(fam, "me", 2) == ["f", "gm", "gp", "m"]
assert ancestors_within(fam, "me", 0) == []

# Descendant fan visits everyone once even through shared ancestors.
assert descendant_fan(fam, "gm") == ["f", "gm", "me", "u"]

# Marriage-aware view: married-in partners appear beside the blood fan.
assert in_laws(fam, "gm") == ["a", "m"]
assert in_laws(fam, "me") == []

# Longest parent-chain depth converges across the diamond.
assert apex_ancestor_depth(fam, "me") == 2
assert apex_ancestor_depth(fam, "gm") == 0

# Cycle-safety: malformed loop data must terminate.
looped = load_family(["x", "y"], [("parent", "x", "y"), ("parent", "y", "x")])
assert descendant_fan(looped, "x") == ["x", "y"]
assert apex_ancestor_depth(looped, "x") == 1

print("iss_asielen__plaintext-family-history__115 ref OK")
