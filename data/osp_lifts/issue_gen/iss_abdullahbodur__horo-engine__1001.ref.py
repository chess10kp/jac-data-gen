"""Reference harness: exercises every public function of iss_abdullahbodur__horo-engine__1001."""
import importlib

mod = importlib.import_module("iss_abdullahbodur__horo-engine__1001")
expand = mod.expand

prefabs = {
    "bot": {
        "root": "body",
        "nodes": {
            "body": {"children": ["head", "arm.l", "arm.r"]},
            "head": {"children": ["cam"]},
            "cam": {"children": []},
            "arm.l": {"children": ["grip.l"]},
            "grip.l": {"children": []},
            "arm.r": {"children": []},
        },
    },
    "pad": {
        "root": "frame",
        "nodes": {"frame": {"children": ["leg1", "leg2"]},
                  "leg1": {"children": []}, "leg2": {"children": []}},
    },
    "solo": {"root": "only", "nodes": {"only": {"children": []}}},
}

# single instance: full hierarchy remapped into the instance namespace
res = expand([{"id": "b1", "prefab": "bot"}], prefabs)
assert res["nodes"] == sorted([
    "inst:b1:arm.l", "inst:b1:arm.r", "inst:b1:body", "inst:b1:cam",
    "inst:b1:grip.l", "inst:b1:head",
])
assert res["edges"] == sorted([
    ["inst:b1:body", "inst:b1:arm.l"], ["inst:b1:body", "inst:b1:arm.r"],
    ["inst:b1:body", "inst:b1:head"], ["inst:b1:head", "inst:b1:cam"],
    ["inst:b1:arm.l", "inst:b1:grip.l"],
])

# shared prefab expands per instance into disjoint ID spaces
res = expand([{"id": "x", "prefab": "solo"}, {"id": "y", "prefab": "solo"}], prefabs)
assert res == {
    "nodes": ["inst:x:only", "inst:y:only"],
    "edges": [],
}

# many instances of different prefabs mix without collisions
res = expand([{"id": "i1", "prefab": "bot"}, {"id": "i2", "prefab": "pad"}, {"id": "i3", "prefab": "solo"}], prefabs)
assert res["nodes"].count("inst:i1:body") == 1
assert res["nodes"].count("inst:i2:frame") == 1
assert "inst:i3:only" in res["nodes"]
assert len(res["nodes"]) == 6 + 3 + 1
assert ["inst:i2:frame", "inst:i2:leg1"] in res["edges"]
assert ["inst:i2:frame", "inst:i2:leg2"] in res["edges"]

# root-only prefab: one node, no edges
res = expand([{"id": "z", "prefab": "solo"}], prefabs)
assert res == {"nodes": ["inst:z:only"], "edges": []}

# nodes unreachable from the prefab root do not expand
sparse = {"tree": {"root": "a", "nodes": {"a": {"children": ["b"]}, "b": {"children": []}, "orphan": {"children": []}}}}
res = expand([{"id": "q", "prefab": "tree"}], sparse)
assert res == {"nodes": ["inst:q:a", "inst:q:b"], "edges": [["inst:q:a", "inst:q:b"]]}

# empty scene expands to nothing
assert expand([], prefabs) == {"nodes": [], "edges": []}

# unknown prefab fails closed with KeyError: no partial result
try:
    expand([{"id": "ok", "prefab": "solo"}, {"id": "bad", "prefab": "ghost"}], prefabs)
    assert False, "expected KeyError"
except KeyError:
    pass
try:
    expand([{"id": "bad", "prefab": "ghost"}], {})
    assert False, "expected KeyError"
except KeyError:
    pass

print("iss_abdullahbodur__horo-engine__1001 ref OK")
