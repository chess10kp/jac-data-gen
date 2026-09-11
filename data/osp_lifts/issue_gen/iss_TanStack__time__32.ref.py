"""Reference harness for iss_TanStack__time__32."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TanStack__time__32.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
mod = _mod.DependenciesModule()
mod.register_event("A", 0, 10)
mod.register_event("B", 10, 20)
mod.register_event("C", 20, 30)
mod.createDependency("A", "B", "FS")
mod.createDependency("B", "C", "FS")
assert mod.validateEventDependencies("B") is True
assert mod.validateEventDependencies("C") is True
shifted = mod.move_event("A", 5, 15)
assert shifted == {"A": (5, 15), "B": (15, 25), "C": (25, 35)}

mod2 = _mod.DependenciesModule()
mod2.register_event("X", 0, 5)
mod2.register_event("Y", 5, 10)
try:
    mod2.createDependency("Y", "X", "FS")
    assert False, "expected cycle rejection"
except _mod.DependencyError as exc:
    assert "circular dependency" in str(exc)

mod3 = _mod.DependenciesModule()
mod3.register_event("S1", 3, 7)
mod3.register_event("S2", 3, 7)
mod3.createDependency("S1", "S2", "SS")
assert mod3.validateEventDependencies("S2") is True
mod3._events["S2"] = (1, 5)
assert mod3.validateEventDependencies("S2") is False

mod4 = _mod.DependenciesModule()
mod4.register_event("F1", 0, 8)
mod4.register_event("F2", 0, 6)
mod4.createDependency("F1", "F2", "FF")
assert mod4.validateEventDependencies("F2") is True
mod4._events["F2"] = (0, 5)
assert mod4.validateEventDependencies("F2") is False

mod5 = _mod.DependenciesModule()
mod5.register_event("P", 10, 20)
mod5.register_event("Q", 0, 5)
mod5.createDependency("P", "Q", "SF")
assert mod5.validateEventDependencies("Q") is True
mod5._events["Q"] = (0, 8)
assert mod5.validateEventDependencies("Q") is False

mod6 = _mod.DependenciesModule()
mod6.register_event("A", 0, 10)
mod6.register_event("B", 10, 20)
mod6.register_event("C", 0, 10)
mod6.register_event("D", 20, 30)
mod6.createDependency("A", "B", "FS")
mod6.createDependency("A", "C", "SS")
mod6.createDependency("B", "D", "FS")
mod6.createDependency("C", "D", "SS")
shifted6 = mod6.move_event("A", 5, 15)
assert shifted6 == {"A": (5, 15), "B": (15, 25), "C": (5, 15), "D": (25, 35)}

try:
    mod.createDependency("A", "missing", "FS")
    assert False, "expected unknown id rejection"
except _mod.DependencyError:
    pass

try:
    mod.register_event("Z", 10, 5)
    assert False, "expected finish-before-start rejection"
except _mod.DependencyError:
    pass

try:
    mod.createDependency("A", "B", "XY")
    assert False, "expected invalid dependency type rejection"
except _mod.DependencyError:
    pass

mod7 = _mod.DependenciesModule()
mod7.register_event("A", 0, 5)
mod7.register_event("B", 5, 10)
mod7.register_event("C", 10, 15)
mod7.createDependency("A", "B", "FS")
mod7.createDependency("B", "C", "FS")
try:
    mod7.createDependency("C", "A", "FS")
    assert False, "expected transitive cycle rejection"
except _mod.DependencyError as exc:
    assert "circular dependency" in str(exc)
print("iss_TanStack__time__32 ref OK")
