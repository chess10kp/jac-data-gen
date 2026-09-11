import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_mediapipe_7",
    Path(__file__).with_name("iss_ryjen__mediapipe__7.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_capability_graph(
    ["text_gen", "cpu_backend", "cgimage_input", "gpu_accel"],
    [
        ("text_gen", "cpu_backend"),
        ("cgimage_input", "gpu_accel"),
        ("gpu_accel", "cpu_backend"),
    ],
    ["cpu_backend", "text_gen"],
)
assert mod.available_features(g) == ["cpu_backend", "text_gen"]
assert mod.blocked_by_missing(g, "cgimage_input") == ["cgimage_input", "gpu_accel"]
print("ok")
