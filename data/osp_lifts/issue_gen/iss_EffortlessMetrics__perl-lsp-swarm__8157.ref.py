"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__8157."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__8157.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
META = {
    "pkg": {"name": "Main", "kind": "package", "start": 0, "end": 200, "provenance": "source-backed"},
    "cls": {"name": "App", "kind": "class", "start": 10, "end": 190, "provenance": "source-backed"},
    "fld": {"name": "size", "kind": "field", "start": 12, "end": 13, "provenance": "source-backed"},
    "meth": {"name": "run", "kind": "method", "start": 30, "end": 150, "provenance": "source-backed"},
    "lex": {"name": "_lex", "kind": "lexical", "start": 32, "end": 140, "provenance": "source-backed"},
    "const": {"name": "C", "kind": "constant", "start": 35, "end": 40, "provenance": "source-backed"},
    "helper": {"name": "helper", "kind": "sub", "start": 50, "end": 100, "provenance": "source-backed"},
}
PARENT = [
    ("pkg", None),
    ("cls", "pkg"),
    ("fld", "cls"),
    ("meth", "cls"),
    ("lex", "meth"),
    ("const", "lex"),
    ("helper", "meth"),
]
BODY = [("meth", "lex"), ("meth", "const"), ("meth", "helper")]
DECLS = ["helper", "pkg", "lex", "meth", "const", "fld", "cls"]

G = _mod.load_declaration_graph(DECLS, PARENT, BODY, META)

assert _mod.outline_visible("method", "source-backed") is True
assert _mod.outline_visible("lexical", "source-backed") is False
assert _mod.outline_visible("class", "generated") is False

assert _mod.source_sort_key(G, "fld") < _mod.source_sort_key(G, "meth")

forest = _mod.project_document_symbols(G)
assert [n["id"] for n in forest] == ["pkg"]
assert forest[0]["children"][0]["id"] == "cls"
assert [c["id"] for c in forest[0]["children"][0]["children"]] == ["fld", "meth"]
assert [c["id"] for c in forest[0]["children"][0]["children"][1]["children"]] == ["const", "helper"]
assert _mod.flatten_identities(forest) == ["pkg", "cls", "fld", "meth", "const", "helper"]

assert _mod.visible_descendants(G, "meth") == ["const", "helper"]
assert _mod.visible_descendants(G, "missing") == []

D_DECLS = ["hub", "left", "right", "leaf"]
D_PARENT = [("hub", None), ("left", "hub"), ("right", "hub"), ("leaf", "left")]
D_META = {
    "hub": {"name": "Hub", "kind": "package", "start": 0, "end": 100, "provenance": "source-backed"},
    "left": {"name": "Left", "kind": "class", "start": 10, "end": 40, "provenance": "source-backed"},
    "right": {"name": "Right", "kind": "class", "start": 20, "end": 50, "provenance": "source-backed"},
    "leaf": {"name": "Leaf", "kind": "field", "start": 30, "end": 31, "provenance": "source-backed"},
}
DG = _mod.load_declaration_graph(
    D_DECLS,
    D_PARENT,
    [],
    D_META,
    reach_edges=[("right", "leaf")],
)
assert _mod.declaration_reach(DG, "hub") == ["left", "right", "leaf"]
assert _mod.declaration_reach(DG, "ghost") == []

DUP_META = {
    "pkg_a": {"name": "Utils", "kind": "package", "start": 0, "end": 50, "provenance": "source-backed"},
    "pkg_b": {"name": "Utils", "kind": "package", "start": 60, "end": 110, "provenance": "source-backed"},
    "fld_a": {"name": "x", "kind": "field", "start": 5, "end": 6, "provenance": "source-backed"},
    "fld_b": {"name": "x", "kind": "field", "start": 65, "end": 66, "provenance": "source-backed"},
}
DUP_PARENT = [("pkg_a", None), ("pkg_b", None), ("fld_a", "pkg_a"), ("fld_b", "pkg_b")]
DUPG = _mod.load_declaration_graph(
    ["pkg_b", "fld_a", "pkg_a", "fld_b"],
    DUP_PARENT,
    [],
    DUP_META,
)
dup_forest = _mod.project_document_symbols(DUPG)
assert [n["id"] for n in dup_forest] == ["pkg_a", "pkg_b"]
assert [c["name"] for c in dup_forest[0]["children"]] == ["x"]
assert [c["name"] for c in dup_forest[1]["children"]] == ["x"]
assert len(_mod.flatten_identities(dup_forest)) == len(set(_mod.flatten_identities(dup_forest)))

G2 = _mod.load_declaration_graph(list(reversed(DECLS)), list(reversed(PARENT)), list(reversed(BODY)), META)
assert _mod.flatten_identities(_mod.project_document_symbols(G2)) == _mod.flatten_identities(forest)
print("iss_EffortlessMetrics__perl-lsp-swarm__8157 ref OK")
