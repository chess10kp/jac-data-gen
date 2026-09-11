"""Reference harness: exercises every public function of rec_17."""
from rec_17_buddy_match import build_office, mutual_buddies, suggestions

office = build_office(
    ["avi", "bree", "cal", "dee", "eli"],
    [
        ("avi", "bree"),
        ("avi", "cal"),
        ("bree", "cal"),
        ("cal", "dee"),
        ("dee", "eli"),
    ],
)

assert mutual_buddies(office, "avi", "bree") == ["cal"]
assert mutual_buddies(office, "dee", "eli") == []
assert mutual_buddies(office, "avi", "dee") == ["cal"]

# Second degree from avi: dee (via bree/cal); cal/bree are direct, excluded.
assert suggestions(office, "avi") == ["dee"]
assert suggestions(office, "eli") == ["cal"]
assert suggestions(office, "cal") == ["eli"]

# Unknown nickname conventions.
assert mutual_buddies(office, "zzz", "avi") == []
assert suggestions(office, "zzz") == []

# Diamond: one candidate reachable via two buddies appears once; cycle safe.
dia = build_office(
    ["a", "b", "c", "d"],
    [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
)
assert suggestions(dia, "a") == ["d"]
assert mutual_buddies(dia, "b", "c") == ["a", "d"]

print("rec_17 ref OK")
