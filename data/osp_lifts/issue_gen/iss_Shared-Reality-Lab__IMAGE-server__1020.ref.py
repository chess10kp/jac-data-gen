"""Reference harness for iss_Shared-Reality-Lab__IMAGE-server__1020."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Shared-Reality-Lab__IMAGE-server__1020.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
reg = _mod.create_registry()
_mod.register_service(
    reg,
    "object-detection",
    outputs=["ca.mcgill.a11y.image.preprocessor.objectDetection"],
)
_mod.register_service(
    reg,
    "object-detection-llm",
    outputs=["ca.mcgill.a11y.image.preprocessor.objectDetection"],
)
_mod.register_service(
    reg,
    "object-grouping",
    required=["ca.mcgill.a11y.image.preprocessor.objectDetection"],
)
_mod.register_service(reg, "caption", required=["object-detection"])

assert _mod.output_providers(reg, "ca.mcgill.a11y.image.preprocessor.objectDetection") == [
    "object-detection",
    "object-detection-llm",
]
assert _mod.build_dependency_graph(reg) == {
    "object-detection": [],
    "object-detection-llm": [],
    "object-grouping": ["object-detection"],
    "caption": ["object-detection"],
}
assert _mod.execution_order(reg) == [
    "object-detection",
    "caption",
    "object-detection-llm",
    "object-grouping",
]
assert _mod.upstream_services(reg, "object-grouping") == ["object-detection"]
assert _mod.has_execution_cycle(reg) is False

reg_svc = _mod.create_registry()
_mod.register_service(reg_svc, "object-detection")
_mod.register_service(reg_svc, "object-grouping", required=["object-detection"])
assert _mod.build_dependency_graph(reg_svc)["object-grouping"] == ["object-detection"]
assert _mod.execution_order(reg_svc) == ["object-detection", "object-grouping"]

reg_miss = _mod.create_registry()
_mod.register_service(reg_miss, "orphan", required=["missing-service"])
assert _mod.build_dependency_graph(reg_miss) == {"orphan": []}
assert _mod.output_providers(reg_miss, "missing-service") == []
assert _mod.upstream_services(reg_miss, "orphan") == []
assert _mod.execution_order(reg_miss) == ["orphan"]

reg_inactive = _mod.create_registry()
_mod.register_service(
    reg_inactive,
    "object-detection",
    outputs=["ca.mcgill.a11y.image.preprocessor.objectDetection"],
    active=False,
)
_mod.register_service(
    reg_inactive,
    "consumer",
    required=["ca.mcgill.a11y.image.preprocessor.objectDetection"],
)
assert _mod.output_providers(reg_inactive, "ca.mcgill.a11y.image.preprocessor.objectDetection") == []
assert _mod.build_dependency_graph(reg_inactive) == {"consumer": []}

reg_diamond = _mod.create_registry()
_mod.register_service(reg_diamond, "d")
_mod.register_service(reg_diamond, "c", required=["d"])
_mod.register_service(reg_diamond, "b", required=["d"])
_mod.register_service(reg_diamond, "a", required=["c", "b"])
assert _mod.upstream_services(reg_diamond, "a") == ["b", "c", "d"]
assert _mod.execution_order(reg_diamond) == ["d", "b", "c", "a"]

reg_cycle = _mod.create_registry()
_mod.register_service(reg_cycle, "x", required=["y"])
_mod.register_service(reg_cycle, "y", required=["x"])
assert _mod.has_execution_cycle(reg_cycle) is True
assert _mod.execution_order(reg_cycle) is None
assert _mod.upstream_services(reg_cycle, "x") == ["y"]

assert _mod.upstream_services(reg, "missing") == []
print("iss_Shared-Reality-Lab__IMAGE-server__1020 ref OK")
print("iss_Shared-Reality-Lab__IMAGE-server__1020 ref OK")
