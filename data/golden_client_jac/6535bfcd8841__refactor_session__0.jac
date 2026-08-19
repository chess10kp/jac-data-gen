glob _KEYMAP: dict = {
    "KeyW": 87, "KeyA": 65, "KeyS": 83, "KeyD": 68, "Space": 32,
    "Tab": 258, "ArrowRight": 262, "ArrowLeft": 263, "ArrowDown": 264, "ArrowUp": 265
};

def _keymap(code: str) -> int {
    return _KEYMAP.get(code, 0);
}
