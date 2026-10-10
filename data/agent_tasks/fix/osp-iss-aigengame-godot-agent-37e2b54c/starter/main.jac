"""Scene validate: recurse into instanced sub-scenes for a composed verdict.

Models the GDA-DF-040 dogfooding case: a parent scene instances child
scenes via PackedScene ext_resource references. A validator walker walks
the instancing graph, collecting per-scene problems so a missing
dependency in a child is attributed to the child file (not the parent).
A cycle guard mirrors the source's depth/visited policy so a cyclic
scene graph terminates with a structured diagnostic instead of looping
forever.
"""

node Scene {
    has path: str = "";
    has valid: bool = True;
    has problems: list[str] = [];

    can describe with Scene entry {
        label = "OK" if here.valid else "BAD";
        print(f"  [{label}] {here.path} -> {here.problems}");
    }
}

edge Instances {
    has ext_resource_type: str = "PackedScene";
}

walker SceneValidator {
    has max_depth: int = 6;
    has depth: int = 0;
    has cycle: bool = False;

    can start with Root entry {
        visit [-->];
    }

    can validate with Scene entry {
        self.depth = self.depth + 1;
        if self.depth > self.max_depth {
            self.cycle = True;
            here.problems = here.problems + [f"cycle: depth>{self.max_depth} via {here.path}"];
            here.valid = False;
            report {"scene": here.path, "problems": here.problems, "cycle": True};
            disengage;
        }
        if "broken" in here.path {
            here.problems = here.problems + ["missing script.gd", "missing icon.png"];
            here.valid = False;
        } else if "good" in here.path {
            here.valid = True;
        }
        if here.problems {
            print(f"problems in {here.path}: {here.problems}");
        }
        visit [->:Instances:->];
    }
}

with entry {
    parent_good = Scene(path="scenes/encounter_good.tscn");
    parent_bad = Scene(path="scenes/encounter_bad.tscn");
    child_ok = Scene(path="scenes/child_ok.tscn");
    child_broken = Scene(path="scenes/child_broken.tscn");
    deep_grandchild = Scene(path="scenes/grandchild.tscn");
    cycle_a = Scene(path="scenes/cycle_a.tscn");
    cycle_b = Scene(path="scenes/cycle_b.tscn");

    parent_good +>:Instances:+> child_ok +>:Instances:+> deep_grandchild;
    parent_bad +>:Instances:+> child_broken;
    cycle_a +>:Instances:+> cycle_b;
    cycle_b +>:Instances:+> cycle_a;

    print("--- validating known-good composed scene ---");
    SceneValidator(max_depth=6) spawn parent_good;
    print("--- validating known-bad composed scene ---");
    SceneValidator(max_depth=6) spawn parent_bad;
    print("--- validating cyclic scene graph ---");
    v = SceneValidator(max_depth=6);
    root ++> v;
    SceneValidator(max_depth=6) spawn cycle_a;
}