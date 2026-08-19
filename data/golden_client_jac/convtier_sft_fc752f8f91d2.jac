node Shim {}
node Register { has name: str; has value: int = 0; }
node Op { has text: str; }

walker DriveShim {
    has regs: list;
    has mode: int = 0;
    can start with Shim entry { visit [-->][?:Op]; }
    can exec with Op entry {
        t = here.text;
        if t == "proj" { self.mode = 0; }
        elif t == "mv" { self.mode = 1; }
        else {
            n = int(t.split(":")[1]);
            reg = self.regs[self.mode];
            if t.startswith("set:") { reg.value = n; }
            elif t.startswith("add:") { reg.value += n; }
            else { reg.value *= n; }
        }
        visit [-->][?:Op];
    }
}

def matrix_stack(spec: dict) -> list {
    shim = Shim();
    proj = Register(name="proj");
    mv = Register(name="mv");
    shim ++> proj;
    shim ++> mv;
    prev = shim;
    for op in spec["ops"] { nxt = Op(text=str(op)); prev ++> nxt; prev = nxt; }
    shim spawn DriveShim(regs=[proj, mv]);
    return [proj.value, mv.value];
}

with entry {
    print(matrix_stack({'ops': ['set:3', 'mul:4', 'mv', 'set:2', 'add:5']}));
}
