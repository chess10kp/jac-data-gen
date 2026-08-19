node Task {
    has name: str;
}

edge DependsOn {}

walker CycleCheck {
    has found: bool = False;

    can start with Root entry {
        for n in [-->] {
            sub = n spawn DFS(path=[]);
            if sub.found {
                self.found = True;
            }
        }
    }
}

walker DFS {
    has path: list = [];
    has found: bool = False;

    can walk with Task entry {
        if here.name in self.path {
            self.found = True;
            disengage;
        }
        new_path = self.path + [here.name];
        for nb in [->:DependsOn:->] {
            sub = nb spawn DFS(path=new_path);
            if sub.found {
                self.found = True;
                disengage;
            }
        }
    }
}

with entry {
    a = Task(name="A");
    b = Task(name="B");
    c = Task(name="C");
    d = Task(name="D");

    root ++> a;
    a +>:DependsOn:+> b;
    b +>:DependsOn:+> c;
    c +>:DependsOn:+> a;
    c +>:DependsOn:+> d;

    w = root spawn CycleCheck();
    print(w.found);
}
