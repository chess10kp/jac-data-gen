#!/usr/bin/env python3
"""Reference harness — open-metadata/OpenMetadata#29323."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_open-metadata__OpenMetadata__29323.py"
spec = importlib.util.spec_from_file_location("om_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["om_mod"] = mod
spec.loader.exec_module(mod)

build_store = mod.build_store


def build_tree() -> mod.MetadataStore:
    s = build_store()
    for eid, kind in [("svc", "service"), ("db", "database"), ("tbl", "table"), ("col", "column")]:
        s.register_entity(eid, kind)
    s.link_child("svc", "db")
    s.link_child("db", "tbl")
    s.link_child("tbl", "col")
    return s


def build_diamond() -> mod.MetadataStore:
    s = build_store()
    for eid in ("root", "left", "right", "join"):
        s.register_entity(eid)
    s.link_child("root", "left")
    s.link_child("root", "right")
    s.link_child("left", "join")
    s.link_child("right", "join")
    return s


def main() -> None:
    s = build_tree()
    assert s.collect_delete_closure("svc") == ["svc", "db", "tbl", "col"]
    deleted = s.bulk_delete("db")
    assert deleted == ["col", "db", "tbl"]
    assert s.exists("svc")
    assert not s.exists("tbl")
    assert s.children_of("svc") == []

    d = build_diamond()
    assert sorted(d.collect_delete_closure("root")) == ["join", "left", "right", "root"]
    assert sorted(d.bulk_delete("root")) == ["join", "left", "right", "root"]
    assert d.collect_delete_closure("missing") == []

    print("ok")


if __name__ == "__main__":
    main()
