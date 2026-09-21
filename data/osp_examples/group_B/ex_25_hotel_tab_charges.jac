"""Hotel service desks charging a guest's tab.

Each desk is a node that reaches into the visiting walker through
``visitor``: it reads the guest's name and adds the price of the
service straight onto the guest's running tab, which survives the
whole trip because walker state persists across nodes.
"""

node ServiceDesk {
    has service: str;
    has price: int;

    can serve with Guest entry {
        visitor.tab += self.price;
        print(f"served {visitor.guest_name}: {self.service} "
              f"(+${self.price}, tab now ${visitor.tab})");
    }
}

walker Guest {
    has guest_name: str;
    has tab: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can enjoy with ServiceDesk entry {
        visit [-->];
    }
}

with entry {
    spa = ServiceDesk(service="spa session", price=90);
    bar = ServiceDesk(service="room-service dinner", price=45);
    laundry = ServiceDesk(service="express laundry", price=20);
    root ++> spa ++> bar ++> laundry;

    alice = Guest(guest_name="Alice");
    root spawn alice;
    bob = Guest(guest_name="Bob");
    root spawn bob;

    print(f"Alice owes ${alice.tab}, Bob owes ${bob.tab}");
}
