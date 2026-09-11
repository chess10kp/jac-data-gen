"""Reference harness for iss_lantisprime__episodic-memory__147."""
import importlib.util
from pathlib import Path

_PATH = Path(__file__).with_name("iss_lantisprime__episodic-memory__147.py")
_spec = importlib.util.spec_from_file_location("trigger147", _PATH)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
TriggerGraph = _mod.TriggerGraph


def _run() -> None:
    g = TriggerGraph()
    g.add_trigger("a", "b")
    g.add_trigger("b", "c")
    g.add_trigger("c", "a")
    cycles = g.find_cycles()
    assert len(cycles) == 1
    assert sorted(cycles[0]) == ["a", "b", "c"]

    g2 = TriggerGraph()
    g2.add_trigger("x", "y")
    g2.add_trigger("y", "z")
    assert g2.find_cycles() == []
    assert g2.would_create_cycle("z", "x") is True
    assert g2.would_create_cycle("z", "w") is False

    # adversarial diamond: revisit before deep first-visit
    g3 = TriggerGraph()
    g3.add_trigger("root", "left")
    g3.add_trigger("root", "right")
    g3.add_trigger("left", "sink")
    g3.add_trigger("right", "sink")
    assert g3.reachable_from("root") == ["left", "right", "sink"]


if __name__ == "__main__":
    _run()
