"""find_channel.run: resolve channel_id via jobj and visit only when it is a Channel."""

node Profile { has username: str = ""; }
node Channel { has name: str = ""; }

walker find_channel {
    has channel_id: str = "";

    can run with Root entry {
        if self.channel_id {
            target = jobj(self.channel_id);
            if isinstance(target, Channel) {
                visit [target];
            }
        }
    }
}

walker check_channel(find_channel) {
    has landed_name: str = "", landed: bool = False;

    can act with Channel entry {
        self.landed = True;
        self.landed_name = here.name;
        disengage;
    }
}

with entry {
    ch = (root ++> Channel(name="jacdevs"))[0];
    p = (root ++> Profile(username="alice"))[0];

    # Resolves to the channel -> lands.
    r1 = root spawn check_channel(channel_id=jid(ch));
    print("channel_landed:", r1.landed);
    print("channel_name:", r1.landed_name);

    # A profile jid is not a Channel -> never visits.
    r2 = root spawn check_channel(channel_id=jid(p));
    print("profile_landed:", r2.landed);

    # Empty target -> never visits.
    r3 = root spawn check_channel();
    print("empty_landed:", r3.landed);
}
