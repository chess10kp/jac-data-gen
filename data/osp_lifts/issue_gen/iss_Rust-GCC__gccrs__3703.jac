"""Rust-GCC/gccrs#3703 — recursive macro expansion graph."""

node Macro {
    has name: str;
    has previous: str = "";
    has variants: list[str];
}

node MacroBook {
    has index: dict[str, Macro] = {};
}

edge Contains {}
edge Expands {}

walker MacroExpansion {
    has target: str;
    has claimed: dict[str, bool] = {};
    has work: list[str] = [];

    can start with MacroBook entry {
        print self.target;
        if self.target in here.index {
            start: Macro = here.index[self.target];
            visit :0: [start];
        }
    }

    can expand_node with Macro entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.work.append(here.name);
        for variant in here.variants {
            self.work.append(here.name + "::" + variant);
        }
        print here.name;
        for prior in [here ->:Expands:->][?:Macro] {
            visit :0: [prior];
        }
    }
}

def new_book -> MacroBook {
    return MacroBook();
}

def define_macro(
    graph_root: MacroBook,
    name: str,
    previous: str = "",
) -> bool {
    if name in graph_root.index {
        return False;
    }
    m = Macro(
        name=name,
        previous=previous,
        variants=["Empty", "First", "Second", "Third", "Fourth"],
    );
    graph_root.index[name] = m;
    graph_root +>:Contains:+> m;
    if previous != "" and previous in graph_root.index {
        prior: Macro = graph_root.index[previous];
        m +>:Expands:+> prior;
    }
    return True;
}

def link_macro(
    graph_root: MacroBook,
    child_name: str,
    previous_name: str,
) -> bool {
    if child_name not in graph_root.index {
        return False;
    }
    if previous_name not in graph_root.index {
        return False;
    }
    child: Macro = graph_root.index[child_name];
    previous: Macro = graph_root.index[previous_name];
    child +>:Expands:+> previous;
    return True;
}

def expand_macro(graph_root: MacroBook, name: str) -> list[str] {
    w = graph_root spawn MacroExpansion(target=name, claimed={});
    return w.work;
}
