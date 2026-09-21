"""Remove a specific typed edge by pinning both endpoints.

`[edge a ->:Friend:-> b]` returns the edge objects themselves, ready
for `del` -- precise even when several edge types connect the same
pair.
"""

node Person {
    has name: str;
}

edge Friend {
    has since: int = 2024;
}

edge Coworker { }  # same pair may carry other relationships too

def make_pair(a_name: str, b_name: str) -> tuple[Person, Person] {
    a = Person(name=a_name);
    b = Person(name=b_name);
    root ++> a;
    root ++> b;
    a +>: Friend(since=2021) :+> b;
    a +>: Friend(since=2023) :+> b;   # duplicate friendship edges
    a +>: Coworker() :+> b;           # survives the unfriend below
    return (a, b);
}

walker list_friends {
    can start with Root entry {
        visit [-->];
    }

    can show with Person entry {
        friends = [here ->:Friend:->];
        report {"person": here.name,
                "friends": sorted([f.name for f in friends]),
                "coworkers": len([here ->:Coworker:->])};
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    carol = Person(name="Carol");
    root ++> alice;
    root ++> bob;
    root ++> carol;
    alice +>: Friend(since=2020) :+> bob;
    bob +>: Friend(since=2019) :+> carol;
    (dup_a, dup_b) = make_pair("Dan", "Eve");

    v1 = root spawn list_friends();
    print("before:", v1.reports);

    # Drop ALL Friend edges between Dan and Eve; Coworker stays intact.
    for e in [edge dup_a ->:Friend:-> dup_b] {
        del e;
    }

    # And the single Alice -> Bob friendship.
    for e in [edge alice ->:Friend:-> bob] {
        del e;
    }

    v2 = root spawn list_friends();
    print("after :", v2.reports);
}
