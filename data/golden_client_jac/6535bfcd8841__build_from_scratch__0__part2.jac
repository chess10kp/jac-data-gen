def _keymap(code: str) -> int {
    m = {
        "KeyW": 87,
        "KeyA": 65,
        "KeyS": 83,
        "KeyD": 68,
        "Space": 32,
        "Tab": 258,
        "ArrowRight": 262,
        "ArrowLeft": 263,
        "ArrowDown": 264,
        "ArrowUp": 265
    };
    return m.get(code, 0);
}

with entry {
    codes = ["KeyW", "ArrowUp", "Space", "Nope"];
    parts = [];
    for code in codes {
        parts.append(str(_keymap(code)));
    }
    print(" ".join(parts));
}
