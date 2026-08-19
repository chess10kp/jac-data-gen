def _is_lib(fn: str, osname: str) -> bool {
    if osname == "Darwin" {
        return fn.startswith("libraylib") and fn.endswith(".dylib");
    }
    return fn.startswith("libraylib.so");
}

with entry {
    cases = [
        ["libraylib.dylib", "Darwin"], ["libraylib.so", "Linux"],
        ["foo.dylib", "Darwin"], ["libraylib.so.5", "Linux"],
        ["libraylib.dylib", "Linux"]
    ];
    for c in cases {
        print(str(_is_lib(c[0], c[1])));
    }
}
