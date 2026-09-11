import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod114",
    Path(__file__).with_name("iss_grandchallenge__QUANTUM-TECHNOLOGIES__114.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

pipe = mod.load_decoder_dag(
    ["compile", "validate", "decode", "score", "compare"],
    [
        ("compile", "validate"),
        ("validate", "decode"),
        ("decode", "score"),
        ("score", "compare"),
    ],
)
assert mod.execution_order(pipe) == ["compile", "validate", "decode", "score", "compare"]
assert mod.compile_validate_decode_order(pipe) == ["compile", "validate", "decode", "score", "compare"]
assert mod.stage_reachable(pipe, "compile") == ["compare", "decode", "score", "validate"]

pipe2 = mod.load_decoder_dag(["a", "b"], [("a", "b"), ("b", "a")])
try:
    mod.execution_order(pipe2)
    assert False, "expected CycleError"
except mod.CycleError:
    pass
print("ok")
