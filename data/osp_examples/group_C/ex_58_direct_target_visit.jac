"""Deliver one parcel to its exact addressee in a sorting hub.

The hub scanner first finds the parcel's destination bin by query and
stores the node object on the walker. Routing between conveyor junctions
then skips filtered queries entirely: each junction visits the stored
target node directly, and the graph's edges decide the path taken.
"""

node Junction {
    has name: str;
}

node Bin {
    has code: str;
}

edge Belt {}

walker Courier {
    has target_code: str;
    has target: Bin | None = None;
    has hops: int = 0;

    can start with Root entry {
        # The scanner looks down the conveyor chains: junction, split,
        # then bin -- three belts ahead
        bins = [root ->:Belt:-> ->:Belt:-> ->:Belt:->][?:Bin];
        for b in bins {
            if b.code == self.target_code {
                self.target = b;
            }
        }
        if self.target is None {
            print(f"No bin {self.target_code}; aborting");
            disengage;
        } else {
            print(f"Parcel bound for bin {self.target_code}; entering conveyors");
            visit [-->];
        }
    }

    can route with Junction entry {
        self.hops += 1;
        print(f"rolling through junction {here.name} (hop {self.hops})");

        # Direct node visit: no query, just go to the stored node.
        # The walker still travels along existing connections.
        t = self.target;
        if t is not None {
            visit t;
        }
    }

    can deliver with Bin entry {
        print(f"Delivered to bin {here.code} after {self.hops} junction hop(s)");
        disengage;   # job done -- stop the walker here
    }
}

with entry {
    intake = Junction(name="Intake");
    left = Junction(name="Left Split");
    right = Junction(name="Right Split");
    bin_a = Bin(code="A-12");
    bin_b = Bin(code="B-07");

    root +>: Belt() :+> intake;
    intake +>: Belt() :+> left;
    intake +>: Belt() :+> right;
    left +>: Belt() :+> bin_a;
    right +>: Belt() :+> bin_b;

    root spawn Courier(target_code="B-07");
}
