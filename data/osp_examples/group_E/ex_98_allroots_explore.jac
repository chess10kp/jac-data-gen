"""Explore every root in the deployment with allroots().

Walks whatever roots exist and counts direct children by type; on a
plain CLI run exactly one root appears, equal to the current root.
"""

node Widget {
    has label: str = "";
}

def census(r: any) -> dict[str, int] {
    counts: dict[str, int] = {};
    for child in [r -->] {
        name = type(child).__name__;
        if name not in counts {
            counts[name] = 1;
        } else {
            counts[name] += 1;
        }
    }
    return counts;
}

with entry {
    root ++> Widget(label="a");
    root ++> Widget(label="b");
    root ++> Widget(label="c");

    roots: list[any] = allroots();
    print("root count:", len(roots));
    for r in roots {
        print("root", jid(r), "census:", census(r));
    }

    # Single-user sanity check: on CLI runs there is only us.
    if len(roots) == 1 {
        print("single-root environment: jid(allroots()[0]) == jid(root):",
              jid(roots[0]) == jid(root));
    }
}
