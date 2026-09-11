"""Reference harness: exercises every public function of rec_13."""
from rec_13_metro_routes import build_metro, min_stops, reachable

net = build_metro(
    ["kings", "cross", "oxford", "bank", "euston"],
    [
        ("kings", "cross", "northern"),
        ("cross", "oxford", "central"),
        ("oxford", "bank", "central"),
        ("euston", "kings", "victoria"),
    ],
)

assert reachable(net, "kings") == ["bank", "cross", "euston", "kings", "oxford"]
assert reachable(net, "bank") == ["bank", "cross", "euston", "kings", "oxford"]

# Hop counts.
assert min_stops(net, "kings", "kings") == 0
assert min_stops(net, "kings", "cross") == 1
assert min_stops(net, "kings", "bank") == 3
assert min_stops(net, "euston", "oxford") == 3

# Negative cases.
split = build_metro(["a", "b", "p", "q"], [("a", "b", "l1"), ("p", "q", "l2")])
assert min_stops(split, "a", "q") == -1          # unreachable island
assert min_stops(split, "a", "zz") == -1         # unknown destination
assert reachable(split, "ghost") == []           # unknown source
assert min_stops(split, "ghost", "a") == -1

print("rec_13 ref OK")
