"""RL driver (pure-lib): raylib_shim._keymap (DOM key-code to raylib keycode lookup).

Origin: this_is_jac/raylib_shooter/web/raylib_shim.cl.jac (the _keymap logic, isolated
from io/time/graph/render machinery). Deterministic: a fixed dict lookup with a default of
0, no Math/GL/IO/time/random, so stdout is byte-identical every run. The marked body is the
unit the policy must regenerate; the with entry block exercises it on fixed inputs and
prints a deterministic projection.
"""

def _keymap(code: str) -> int {
    # >>>HOLE id="lib_keymap" instruction="Map a DOM key-code string to a raylib integer keycode. Build a dict with these entries: 'KeyW'->87, 'KeyA'->65, 'KeyS'->83, 'KeyD'->68, 'Space'->32, 'Tab'->258, 'ArrowRight'->262, 'ArrowLeft'->263, 'ArrowDown'->264, 'ArrowUp'->265. Return the value for code, or 0 if code is not present."
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
    # <<<HOLE
}

with entry {
    codes = ["KeyW", "ArrowUp", "Space", "Nope"];
    parts = [];
    for code in codes {
        parts.append(str(_keymap(code)));
    }
    print(" ".join(parts));
}
