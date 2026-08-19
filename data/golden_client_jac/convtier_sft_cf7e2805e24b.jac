node Pad {}
node Binding { has code: str; has key: int; }

walker Lookup {
    has code: str;
    has result: int = 0, found: bool = False;
    can start with Pad entry { visit [-->]; }
    can check with Binding entry {
        if not self.found and here.code == self.code {
            self.result = here.key;
            self.found = True;
        }
    }
}

def key_lookup(spec: dict) -> int {
    pad = Pad();
    for b in spec["bindings"] { pad ++> Binding(code=str(b[0]), key=int(b[1])); }
    return (pad spawn Lookup(code=str(spec["code"]))).result;
}

with entry {
    print(key_lookup({'bindings': [['KeyW', 87], ['KeyA', 65], ['Space', 32], ['ArrowUp', 265]], 'code': 'Space'}));
}
