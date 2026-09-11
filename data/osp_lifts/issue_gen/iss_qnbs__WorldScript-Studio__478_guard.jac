"""qnbs/WorldScript-Studio#478 — candidate + hidden guards."""

import from iss_qnbs__WorldScript-Studio__478 {
    OfflineManifest,
}

test "linear precache chain" {
    m = OfflineManifest();
    m.register_asset("index.html");
    m.require("index.html", "app.js");
    m.require("app.js", "chunk-vendors.js");
    m.require("app.js", "wasm-runtime.wasm");
    assert m.offline_closure("index.html") == [
        "app.js",
        "chunk-vendors.js",
        "wasm-runtime.wasm",
    ];
    assert m.offline_closure("app.js") == ["chunk-vendors.js", "wasm-runtime.wasm"];
    assert m.offline_closure("wasm-runtime.wasm") == [];
    assert m.offline_closure("missing") == [];
}

test "diamond adversarial edge order" {
    m = OfflineManifest();
    # insert merge target before hub arms — stresses revisit ordering
    m.require("icons.svg", "sprite.svg");
    m.require("fonts.woff2", "sprite.svg");
    m.require("app-shell", "icons.svg");
    m.require("app-shell", "fonts.woff2");
    assert m.offline_closure("app-shell") == ["fonts.woff2", "icons.svg", "sprite.svg"];
}

test "cycle claim-map not disengage" {
    m = OfflineManifest();
    m.require("a", "b");
    m.require("b", "c");
    m.require("c", "a");
    m.require("b", "d");
    assert m.offline_closure("a") == ["b", "c", "d"];
}

test "idempotent register_asset" {
    m = OfflineManifest();
    m.register_asset("sw.js");
    m.register_asset("sw.js");
    assert m.offline_closure("sw.js") == [];
}
