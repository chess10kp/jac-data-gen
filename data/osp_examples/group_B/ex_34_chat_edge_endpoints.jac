"""Chat platform reactions with edge inheritance.

The base edge ``Reacts`` connects Account --> Message. Its subtypes
show the two inheritance options: ``Echo(Reacts)`` inherits the
endpoints untouched, while ``StaffPin(Reacts): Moderator --> Message``
re-declares the source endpoint so only moderator accounts may create
pinned reactions. Endpoint-aware traversals infer Message targets.
"""

node Account {
    has handle: str;
}

node Moderator(Account) {
    has team: str = "";
}

node Message {
    has body: str;
}

edge Reacts: Account --> Message {
    has emoji: str = "";
}

edge Echo(Reacts) {}

edge StaffPin(Reacts): Moderator --> Message {
    has pinned_at: str = "";
}

walker ChannelReader {
    can start with Root entry {
        visit [-->];
    }

    can browse with Account entry {
        for message in [->:Reacts:->] {
            print(f"@{here.handle} reacted to '{message.body}'");
        }
        visit [-->];
    }

    can read with Message entry {
        print(f"reading message: '{here.body}'");
    }
}

with entry {
    mod_dana = Moderator(handle="dana", team="trust-safety");
    regular_eli = Account(handle="eli");

    m1 = Message(body="deploy finished");
    m2 = Message(body="lunch poll results");
    m3 = Message(body="welcome new folks");

    root ++> mod_dana;
    mod_dana +>: StaffPin(emoji="pushpin", pinned_at="09:00") :+> m1;
    mod_dana +>: Echo(emoji="eyes") :+> m3;
    root ++> regular_eli;
    regular_eli +>: Reacts(emoji="thumbsup") :+> m2;

    reader = ChannelReader();
    root spawn reader;
}
