#!/usr/bin/env python3
"""Reference harness for iss_qnbs__WorldScript-Studio__478.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_qnbs__WorldScript-Studio__478.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)


def main() -> None:
  m = mod.OfflineManifest()

    # shell -> app shell chunks -> wasm runtime
    m.register_asset("index.html")
    m.require("index.html", "app.js")
    m.require("app.js", "chunk-vendors.js")
    m.require("app.js", "wasm-runtime.wasm")
    assert m.offline_closure("index.html") == [
        "app.js",
        "chunk-vendors.js",
        "wasm-runtime.wasm",
    ]
    assert m.offline_closure("app.js") == ["chunk-vendors.js", "wasm-runtime.wasm"]
    assert m.offline_closure("wasm-runtime.wasm") == []
    assert m.offline_closure("missing") == []

    # diamond adversarial order: merge before hub arms
    d = mod.OfflineManifest()
    d.require("icons.svg", "sprite.svg")
    d.require("fonts.woff2", "sprite.svg")
    d.require("app-shell", "icons.svg")
    d.require("app-shell", "fonts.woff2")
    assert d.offline_closure("app-shell") == ["fonts.woff2", "icons.svg", "sprite.svg"]

    # cycle: a->b->c->a plus side branch b->d
    c = mod.OfflineManifest()
    c.require("a", "b")
    c.require("b", "c")
    c.require("c", "a")
    c.require("b", "d")
    assert c.offline_closure("a") == ["b", "c", "d"]

    # idempotent register
    solo = mod.OfflineManifest()
    solo.register_asset("sw.js")
    solo.register_asset("sw.js")
    assert solo.offline_closure("sw.js") == []

    print("ok")


if __name__ == "__main__":
    main()
