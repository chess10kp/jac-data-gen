node Keymap {}
node Binding { has key: str, action: str; }

walker Translate {
    has keys: list;
    has table: dict = {}, combo: str = "";
    can start with Keymap entry { visit [-->][?:Binding]; }
    can learn with Binding entry { self.table[here.key] = here.action; }
    can build with exit {
        actions: list = [];
        for k in self.keys { actions.append(self.table.get(k, "noop")); }
        self.combo = ">".join(actions);
    }
}

def combo_actions(spec: dict) -> str {
    keymap = Keymap();
    for b in spec["bindings"] {
        keymap ++> Binding(key=str(b[0]), action=str(b[1]));
    }
    keys: list = [str(k) for k in spec["keys"]];
    return (keymap spawn Translate(keys=keys)).combo;
}

with entry {
    print(combo_actions({'bindings': [['w', 'forward'], ['s', 'back'], ['a', 'left'], ['d', 'right'], ['sp', 'fire']], 'keys': ['w', 'w', 'sp', 'q']}));
}
