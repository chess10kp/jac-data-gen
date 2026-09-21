"""Cycle detection in a software build dependency graph.

Modules depend on each other through DependsOn edges. A detector walker
recurses by spawning itself on each dependency: every spawn instance owns
one stack frame, so a module that is mid-exploration ("visiting") seen
again from below is a genuine back edge, and the trail carried down the
spawn chain reconstructs the cycle.
"""

node Module {
    has name: str;
    has status: str = "new";  # new | visiting | done
}

edge DependsOn: Module --> Module {}

walker CycleDetector {
    has trail: list[str] = [];
    has found: str = "";

    can explore with Module entry {
        if here.status == "done" {
            skip;  # whole subtree proven acyclic
        }
        if here.status == "visiting" {
            # Back edge: everything from its first occurrence is the cycle.
            idx = self.trail.index(here.name);
            self.found = " -> ".join(self.trail[idx:] + [here.name]);
            disengage;
        }

        here.status = "visiting";
        next_trail = self.trail + [here.name];
        for dep in [->:DependsOn:->] {
            sub = dep spawn CycleDetector(trail=next_trail);
            if sub.found != "" {
                self.found = sub.found;
                disengage;
            }
        }
        here.status = "done";
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Module] {
        del stale_node;
    }
    linker = Module(name="linker");
    parser = Module(name="parser");
    lexer = Module(name="lexer");
    utils = Module(name="utils");
    codegen = Module(name="codegen");

    # Acyclic core: linker -> parser -> lexer -> utils, linker -> codegen
    linker +>: DependsOn() :+> parser;
    parser +>: DependsOn() :+> lexer;
    lexer +>: DependsOn() :+> utils;
    linker +>: DependsOn() :+> codegen;
    codegen +>: DependsOn() :+> utils;
    # Introduce a real cycle: parser's build step depends on codegen,
    # which already depends on parser.
    codegen +>: DependsOn() :+> parser;
    parser +>: DependsOn() :+> codegen;

    result = linker spawn CycleDetector();
    if result.found {
        print(f"CYCLE DETECTED: {result.found}");
    } else {
        print("Dependency graph is clean -- no cycles.");
    }
}
