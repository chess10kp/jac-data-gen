"""Reference harness for iss_TheBigSasha__windows_hdr_screenshot__15."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TheBigSasha__windows_hdr_screenshot__15.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
dep = _mod.build_dep_graph(
    ["bundle", "cli", "gui", "hdrshot", "numpy", "pyside6", "pillow_heif"],
    [
        ("bundle", "cli"),
        ("bundle", "gui"),
        ("cli", "hdrshot"),
        ("gui", "pyside6"),
        ("gui", "hdrshot"),
        ("gui", "pillow_heif"),
        ("hdrshot", "numpy"),
    ],
)

assert _mod.transitive_deps(dep, "gui") == ["hdrshot", "numpy", "pillow_heif", "pyside6"]
assert _mod.transitive_deps(dep, "bundle") == [
    "cli",
    "gui",
    "hdrshot",
    "numpy",
    "pillow_heif",
    "pyside6",
]
assert _mod.transitive_deps(dep, "missing") == []

assert _mod.paths_between(dep, "bundle", "numpy") == [
    ["bundle", "cli", "hdrshot", "numpy"],
    ["bundle", "gui", "hdrshot", "numpy"],
]
assert _mod.paths_between(dep, "bundle", "numpy", max_depth=3) == []

wf = _mod.build_workflow(
  # adversarial insertion: gui path listed before cli in transitions
    ["start", "check_python", "create_venv", "pip_install", "install_sentinel", "launch_gui"],
    [
        ("start", "check_python"),
        ("check_python", "create_venv"),
        ("create_venv", "pip_install"),
        ("pip_install", "install_sentinel"),
        ("install_sentinel", "launch_gui"),
    ],
)

assert _mod.is_reachable(wf, "start", "launch_gui") is True
assert _mod.is_reachable(wf, "pip_install", "ghost") is False

done_no_sentinel = {"start", "check_python", "create_venv", "pip_install"}
assert _mod.launch_allowed(wf, done_no_sentinel) is False

done_ok = {
    "start",
    "check_python",
    "create_venv",
    "pip_install",
    "install_sentinel",
}
assert _mod.launch_allowed(wf, done_ok) is True
assert _mod.launch_allowed(wf, done_ok, launch_step="ghost") is False

assert _mod.version_drift(
    {
        "pyproject.toml": {"hdrshot": "0.1.0"},
        "__init__.py": {"hdrshot": "0.1.0"},
        "requirements.txt": {"numpy": "2.1.0"},
    }
) == []
assert _mod.version_drift(
    {
        "pyproject.toml": {"hdrshot": "0.1.0"},
        "__init__.py": {"hdrshot": "0.1.1"},
    }
) == ["hdrshot"]

cyc = _mod.build_dep_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.transitive_deps(cyc, "a") == ["b", "c"]
assert _mod.is_reachable(cyc, "a", "c") is True

print("iss_TheBigSasha__windows_hdr_screenshot__15 ref OK")
print("iss_TheBigSasha__windows_hdr_screenshot__15 ref OK")
