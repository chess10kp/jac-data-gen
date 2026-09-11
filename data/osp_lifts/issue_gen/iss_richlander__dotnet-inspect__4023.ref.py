import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_dotnet_4023",
    Path(__file__).with_name("iss_richlander__dotnet-inspect__4023.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_overlay(
    ["GetUser", "BuildUri", "GetFromJson", "Parse", "ParseList"],
    [
        ("GetUser", "BuildUri"),
        ("GetUser", "GetFromJson"),
        ("Parse", "ParseList"),
        ("ParseList", "Parse"),
    ],
)
assert mod.callees_within(g, "GetUser", 2) == ["BuildUri", "GetFromJson"]
assert mod.callers_within(g, "Parse", 2) == ["Parse", "ParseList"]
assert mod.fan_in(g, "GetFromJson") == 1
print("ok")
