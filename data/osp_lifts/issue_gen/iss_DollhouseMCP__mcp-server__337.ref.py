"""Reference harness: exercises every public function of iss_DollhouseMCP__mcp-server__337."""
import importlib

mod = importlib.import_module("iss_DollhouseMCP__mcp-server__337")
related_within = mod.related_within
contradiction_pairs = mod.contradiction_pairs

# knowledge snippet: decision -> outcome with cross-references and a contradiction
S = {
    "memories": ["m1", "m2", "m3", "m4", "m5", "m6"],
    "links": [
        ("m1", "m2", "builds_on", 0.9),
        ("m2", "m3", "caused_by", 0.7),
        ("m3", "m4", "references", 0.5),
        ("m1", "m5", "similar_to", 0.8),
        ("m5", "m6", "contradicts", 0.6),
        ("m2", "m3", "references", 0.4),  # parallel link, same pair
    ],
}

# multi-hop neighborhoods (shortest link distance)
assert related_within(S, "m1", hops=1) == ["m2", "m5"]
assert related_within(S, "m1", hops=2) == ["m2", "m3", "m5", "m6"]
assert related_within(S, "m1", hops=3) == ["m2", "m3", "m4", "m5", "m6"]
assert related_within(S, "m1", hops=4) == ["m2", "m3", "m4", "m5", "m6"]
assert related_within(S, "m6", hops=2) == ["m1", "m5"]
assert related_within(S, "m4", hops=1) == ["m3"]

# default hops=2
assert related_within(S, "m1") == ["m2", "m3", "m5", "m6"]

# adversarial-order diamond: long branch linked before the direct link, so
# the shared memory is first reached deep and must improve to shallow
D = {
    "memories": ["a", "b", "c", "d"],
    "links": [
        ("a", "b", "references", 0.9),
        ("b", "c", "references", 0.9),
        ("c", "d", "references", 0.9),
        ("a", "d", "similar_to", 0.5),
    ],
}
assert related_within(D, "a", hops=1) == ["b", "d"]  # d at 1 hop, not 3
assert related_within(D, "a", hops=2) == ["b", "c", "d"]

# link cycles terminate via the distance map
C = {
    "memories": ["p", "q", "r"],
    "links": [
        ("p", "q", "references", 0.9),
        ("q", "r", "references", 0.9),
        ("r", "p", "part_of", 0.9),
    ],
}
assert related_within(C, "p", hops=2) == ["q", "r"]

# lone memory and unknown start
assert related_within({"memories": ["solo"], "links": []}, "solo", hops=3) == []
try:
    related_within(S, "ghost", hops=1)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

# unknown ids in links are skipped by both functions
U = {
    "memories": ["a", "b"],
    "links": [
        ("a", "ghost", "references", 0.9),
        ("a", "b", "contradicts", 0.6),
        ("ghost", "b", "contradicts", 0.6),
    ],
}
assert related_within(U, "a", hops=2) == ["b"]
assert contradiction_pairs(U) == [["a", "b"]]

# contradiction pairs: deduped, canonicalized (a < b), sorted
assert contradiction_pairs(S) == [["m5", "m6"]]
B = {
    "memories": ["x", "y", "z", "w"],
    "links": [
        ("z", "x", "contradicts", 0.9),  # reversed order canonicalized
        ("x", "z", "contradicts", 0.4),  # duplicate pair
        ("y", "w", "contradicts", 0.7),
        ("y", "x", "builds_on", 0.9),    # not a contradiction
    ],
}
assert contradiction_pairs(B) == [["w", "y"], ["x", "z"]]
assert contradiction_pairs({"memories": ["a"], "links": []}) == []

print("iss_DollhouseMCP__mcp-server__337 ref OK")
