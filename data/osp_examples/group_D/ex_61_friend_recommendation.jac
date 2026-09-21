"""Friend recommendation for a small social network.

Builds a social graph of people connected by Knows edges, then walks the
friends-of-friends of one member and suggests people they are not yet
connected to, ranked by number of mutual friends via a lambda-key sort.
"""

node Person {
    has name: str;
}

edge Knows: Person --> Person {}

walker FriendRecommender {
    has known: dict = {};
    has candidates: list[dict] = [];

    can recommend with Person entry {
        # Step 1: remember everyone this person already knows.
        for friend in [->:Knows:->] {
            self.known[friend.name] = True;
        }

        # Step 2: collect every friend-of-friend that is not already
        # known; duplicates are kept so they can be tallied as mutuals.
        fofs: list[str] = [];
        for friend in [->:Knows:->] {
            for fof in [friend ->:Knows:->] {
                if fof.name == here.name or fof.name in self.known {
                    continue;
                }
                fofs.append(fof.name);
            }
        }

        # Step 3: tally unique candidates and their mutual-friend counts.
        for cand in fofs {
            found = False;
            for c in self.candidates {
                if c["name"] == cand {
                    c["mutuals"] += 1;
                    found = True;
                }
            }
            if not found {
                self.candidates.append({"name": cand, "mutuals": 1});
            }
        }

        # Step 4: rank candidates by mutual count, best first.
        self.candidates.sort(key=lambda (c: any) { c["mutuals"]; }, reverse=True);

        print(f"Friend suggestions for {here.name}:");
        if len(self.candidates) == 0 {
            print("  (no suggestions -- network too small)");
        }
        for c in self.candidates {
            print(f"  {c['name']} ({c['mutuals']} mutual friend(s))");
        }
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Person] {
        del stale_node;
    }
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    carol = Person(name="Carol");
    dave = Person(name="Dave");
    erin = Person(name="Erin");
    frank = Person(name="Frank");

    alice +>: Knows() :+> bob;
    alice +>: Knows() :+> carol;
    bob +>: Knows() :+> carol;
    bob +>: Knows() :+> dave;
    carol +>: Knows() :+> dave;
    carol +>: Knows() :+> erin;
    dave +>: Knows() :+> erin;
    frank +>: Knows() :+> erin;  # Frank is only reachable through Erin

    alice spawn FriendRecommender();
}
