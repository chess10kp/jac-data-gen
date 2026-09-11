import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_lsst-sqre__ook__237",
    Path(__file__).with_name("iss_lsst-sqre__ook__237.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_entities(
    ["lsst.afw", "lsst.afw.table", "lsst.afw.table.SourceCatalog"],
    [("lsst.afw.table.SourceCatalog", "class"), ("lsst.afw.table", "module")],
    [
        ("lsst.afw.table", "lsst.afw"),
        ("lsst.afw.table.SourceCatalog", "lsst.afw.table"),
    ],
)
assert mod.direct_children(store, "lsst.afw") == ["lsst.afw.table"]
assert mod.all_descendants(store, "lsst.afw") == [
    "lsst.afw.table",
    "lsst.afw.table.SourceCatalog",
]
assert mod.ancestor_chain(store, "lsst.afw.table.SourceCatalog") == [
    "lsst.afw",
    "lsst.afw.table",
]
assert mod.entity_role(store, "lsst.afw.table.SourceCatalog") == "class"

store_d = mod.load_entities(
    ["root", "left", "right", "leaf"],
    [],
    [("left", "root"), ("right", "root"), ("leaf", "left"), ("leaf", "right")],
)
assert mod.all_descendants(store_d, "root") == ["leaf", "left", "right"]
print("ok")
