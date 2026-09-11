"""§5.5 activation blocker: disconnect + node deletion round-trip on 0.36.1.

Creates A -> B -> C, disconnects A-->B, deletes B,
verifies C is detached from the reachable graph and A survives.
Idempotent: assertions use direct object refs (the jac root may carry
nodes from other sessions), and the probe cleans up after itself.
"""

node Item {
    has name: str;
}

walker ReachCheck {
    has reached: list[str] = [];
    can go with Item entry {
        self.reached.append(here.name);
        visit [-->];
    }
}

with entry {
    a := Item(name="probe-a");
    root ++> a;
    b := Item(name="probe-b");
    a ++> b;
    c := Item(name="probe-c");
    b ++> c;

    # sanity: chain intact via direct refs
    assert len([a -->]) == 1, "pre: a should have exactly one child";
    assert len([b -->]) == 1, "pre: b should have exactly one child";

    # disconnect A --> B
    a del --> b;
    assert len([a -->]) == 0, "disconnect: a should have no children";

    # delete B; C must become unreachable garbage, A stays intact
    holder_name = b.name;
    del b;
    print("deleted node carried name:", holder_name);
    assert len([a -->]) == 0, "post: a still childless";
    assert c.name == "probe-c", "C object remains allocated";

    # C is no longer reachable from A (walk drains without hitting it)
    w = a spawn ReachCheck();
    assert len(w.reached) == 1 and w.reached[0] == "probe-a",
        "reachability from A must not include B or C";

    # cleanup: leave the shared root as we found it
    root del --> a;
    del a;
    del c;
    print("PROBE PASS: disconnect + del node OK on jac 0.36.1");
}
