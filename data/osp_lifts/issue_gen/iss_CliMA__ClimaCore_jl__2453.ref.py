"""Reference harness for iss_CliMA__ClimaCore_jl__2453."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_CliMA__ClimaCore_jl__2453.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
MODEL = {
    "var_deps": {
        "c.J": ("Y.u_h",),
        "f.rho": ("Y.rho", "c.J"),
        "f.u3": ("Y.u_h",),
    },
    "tend_deps": {
        "Yt.rho": ("f.rho", "f.u3"),
    },
    "var_compute": {
        "c.J": lambda vars, t: vars["Y.u_h"] * 2.0,
        "f.rho": lambda vars, t: vars["Y.rho"] / vars["c.J"],
        "f.u3": lambda vars, t: vars["Y.u_h"] + t,
    },
    "tend_compute": {
        "Yt.rho": lambda vars, t: -(vars["f.rho"] * vars["f.u3"]),
    },
}

graph = _mod.build_dependency_graph(
    ["Yt.rho"],
    ["Y.rho", "Y.u_h"],
    MODEL,
)
assert _mod.get_evaluation_order(graph) == ["c.J", "f.rho", "f.u3", "Yt.rho"]
assert _mod.dependency_chain(graph, "Yt.rho") == [
    "Y.rho",
    "Y.u_h",
    "c.J",
    "f.rho",
    "f.u3",
]
assert _mod.dependency_chain(graph, "missing") == []

y = {"Y.rho": 12.0, "Y.u_h": 4.0}
y_t: dict[str, float] = {}
_mod.evaluate_graph(y_t, y, graph, MODEL, 0.5, _mod.EagerGlobalCaching())
assert y_t == {"Yt.rho": -6.75}
assert sorted(graph.cache.keys()) == ["Yt.rho", "c.J", "f.rho", "f.u3"]

y_t_lazy: dict[str, float] = {}
graph_lazy = _mod.build_dependency_graph(
    ["Yt.rho"],
    ["Y.rho", "Y.u_h"],
    MODEL,
)
_mod.evaluate_graph(y_t_lazy, y, graph_lazy, MODEL, 0.5, _mod.LazyCaching())
assert y_t_lazy == {"Yt.rho": -6.75}
assert graph_lazy.cache == {}

diamond_model = {
    "var_deps": {
        "b": ("a",),
        "c": ("a",),
        "d": ("b", "c"),
    },
    "tend_deps": {},
    "var_compute": {
        "b": lambda vars, t: vars["a"] + 1.0,
        "c": lambda vars, t: vars["a"] + 2.0,
        "d": lambda vars, t: vars["b"] + vars["c"],
    },
    "tend_compute": {},
}
diamond = _mod.build_dependency_graph([], ["a"], diamond_model)
assert _mod.get_evaluation_order(diamond) == ["b", "c", "d"]

cyclic_model = {
    "var_deps": {
        "x": ("y",),
        "y": ("x",),
    },
    "tend_deps": {},
    "var_compute": {
        "x": lambda vars, t: 1.0,
        "y": lambda vars, t: 1.0,
    },
    "tend_compute": {},
}
cyclic = _mod.build_dependency_graph([], [], cyclic_model)
assert _mod.get_evaluation_order(cyclic) is None
y_t_cyc: dict[str, float] = {}
try:
    _mod.evaluate_graph(y_t_cyc, {}, cyclic, cyclic_model, 0.0, _mod.EagerGlobalCaching())
    assert False, "expected cyclic dependency graph"
except ValueError as err:
    assert str(err) == "cyclic dependency graph"

bad_model = {
    "var_deps": {"ghost": ("Y.missing",)},
    "tend_deps": {},
    "var_compute": {"ghost": lambda vars, t: 0.0},
    "tend_compute": {},
}
try:
    _mod.build_dependency_graph([], ["Y.rho"], bad_model)
    assert False, "expected unknown node"
except KeyError as err:
    assert "unknown node" in str(err)
print("iss_CliMA__ClimaCore_jl__2453 ref OK")
