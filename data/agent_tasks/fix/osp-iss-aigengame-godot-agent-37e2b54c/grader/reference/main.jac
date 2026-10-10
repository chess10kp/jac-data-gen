"""Scene validator: model Godot scenes that instance sub-scenes and validate them
as a composed verdict, with cycle-safe traversal and per-file problem attribution.

A `Scene` may instance another `Scene` via a typed `Instances` edge. The
`SceneValidator` walker traverses instances, accumulates problems keyed by
the file each problem originated from, and guards against cycles.
"""

node Scene {
    has path: str = "";
    has valid: bool = True;
    has problems: list[str] = [];
}

edge Instances {
    has instance_id: str = "";
}

walker SceneValidator {
    has visited: list[str] = [];
    has depth: int = 0;
    has max_depth: int = 8;
    has cycle_detected: bool = False;

    can start with Root entry {
        visit [->:Instances:->];
    }

    can validate with Scene entry {
        # Cycle policy: explicit guard set + depth cap. Both terminate
        # traversal with a structured diagnostic instead of looping forever.
        if here.path in self.visited {
            self.cycle_detected = True;
            here.problems.append(f"cycle: already visited {here.path}");
            here.valid = False;
            disengage;
        }
        self.visited.append(here.path);

        if self.depth >= self.max_depth {
            here.problems.append(f"depth cap {self.max_depth} reached at {here.path}");
            here.valid = False;
            disengage;
        }
        self.depth += 1;

        # Seed problems per-scene (these stand in for the real Godot
        # script/texture/missing-ext_resource checks performed in #664).
        if here.path == "child.tscn" {
            here.problems.append("missing script: res://broken.gd");
            here.problems.append("missing texture: res://missing.png");
            here.valid = False;
        }
        if here.path == "grandchild.tscn" {
            here.problems.append("missing ext_resource: res://orphan.tres");
            here.valid = False;
        }

        # Recurse into instanced sub-scenes. Dead-end is handled by the
        # `else` branch on an empty frontier.
        visit [->:Instances:->] else {
            disengage;
        }
    }
}

with entry {
    # Composed scene graph: parent instances child, child instances grandchild,
    # and a cycle edge from grandchild back to parent to prove the cycle guard.
    parent = Scene(path="parent.tscn");
    child = Scene(path="child.tscn");
    grandchild = Scene(path="grandchild.tscn");

    root +>:Instances(instance_id="p->c"):+> parent;
    parent +>:Instances(instance_id="parent->child"):+> child;
    child +>:Instances(instance_id="child->grandchild"):+> grandchild;
    grandchild +>:Instances(instance_id="gc->parent-cycle"):+> parent;

    # A separate known-good subtree so the demo also covers the green path.
    good_root = Scene(path="good_parent.tscn");
    good_child = Scene(path="good_child.tscn");
    good_root +>:Instances(instance_id="g->gc"):+> good_child;

    validator = SceneValidator();
    root spawn validator;

    # Walk the green subtree independently so we can demonstrate the
    # known-good verdict alongside the known-bad composed verdict.
    good_validator = SceneValidator();
    good_root spawn good_validator;

    print("=== composed known-bad validation ===");
    for n in [parent, child, grandchild] {
        status = "valid" if n.valid else "INVALID";
        print(f"{n.path}: {status}");
        for p in n.problems {
            print(f"  - {p}");
        }
    }
    print(f"cycle detected: {validator.cycle_detected}");

    print("=== composed known-good validation ===");
    for n in [good_root, good_child] {
        status = "valid" if n.valid else "INVALID";
        print(f"{n.path}: {status}");
        for p in n.problems {
            print(f"  - {p}");
        }
    }
}
