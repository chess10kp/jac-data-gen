"""Reference harness: exercises every public function of rec_16."""
from rec_16_influence import build_roster, inner_circle, separation

net = build_roster(
    ["ana", "bo", "cy", "di", "el", "fox"],
    [
        ("ana", "bo"),
        ("bo", "cy"),
        ("cy", "di"),
        ("di", "el"),
        ("el", "fox"),
        ("fox", "ana"),   # cycle closes the ring
        ("ana", "cy"),    # shortcut: cy is 1 hop, not 2
    ],
)

# Radius rings respect exact distances (cy via shortcut).
assert inner_circle(net, "ana", 0) == ["ana"]
assert inner_circle(net, "ana", 1) == ["ana", "bo", "cy"]
assert inner_circle(net, "ana", 2) == ["ana", "bo", "cy", "di"]
assert inner_circle(net, "ana", 9) == ["ana", "bo", "cy", "di", "el", "fox"]

assert separation(net, "ana", "ana") == 0
assert separation(net, "ana", "cy") == 1
assert separation(net, "fox", "cy") == 2

# Directed ring: bo still reaches ana after five follow-hops.
assert separation(net, "bo", "ana") == 5
line = build_roster(["p", "q"], [("p", "q")])
assert separation(line, "q", "p") == -1

# Unknown handles.
assert inner_circle(net, "zzz", 2) == []
assert separation(net, "ana", "zzz") == -1
assert separation(net, "zzz", "ana") == -1

print("rec_16 ref OK")
