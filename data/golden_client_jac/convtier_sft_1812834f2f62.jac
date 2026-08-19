node Switch { has name: str; has on_state: bool; has checked: bool = False; }

walker Verify {
    has ok: bool = True;
    can check with Switch entry {
        if not here.checked {
            here.checked = True;
            if not here.on_state { self.ok = False; disengage; }
            visit [-->];
        }
    }
}

def all_flags_set(spec: dict) -> bool {
    adj: dict = spec["adj"]; flags: dict = spec["flags"];
    found: list = list(adj.keys());
    for group in adj.values() { for g in group { if g not in found { found.append(g); } } }
    sw: dict = {};
    for nm in found { sw[nm] = Switch(name=nm, on_state=flags[nm]); }
    for (src, group) in adj.items() { for g in group { sw[src] ++> sw[g]; } }
    w = sw[spec["start"]] spawn Verify();
    return w.ok;
}

with entry {
    print(all_flags_set({'adj': {'a': ['b'], 'b': ['c'], 'c': []}, 'flags': {'a': True, 'b': True, 'c': True}, 'start': 'a'}));
}
