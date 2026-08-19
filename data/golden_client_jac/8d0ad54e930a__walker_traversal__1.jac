"""RL driver (graph): social_graph.find_channel.run.

Origin: this_is_jac/littlex/social_graph.jac. `find_channel` is the lookup base
walker: given a channel_id it resolves the node via jobj and, only when that node
is a Channel, visits it so action subclasses can react. The marked body is the
`run` ability; a tiny subclass reports the name of the channel it lands on. The
entry block resolves the real jid of a fixed channel and prints a deterministic
landed/name projection (the random jid itself is never printed).
"""

node Profile { has username: str = ""; }
node Channel { has name: str = ""; }

walker find_channel {
    has channel_id: str = "";

    can run with Root entry {
        # >>>HOLE id="sg_find_channel_run" instruction="Implement the run ability (walker find_channel, on Root entry). Only when self.channel_id is set, resolve target = jobj(self.channel_id); if that resolved object isinstance Channel, visit [target]."
        if self.channel_id {
            target = jobj(self.channel_id);
            if isinstance(target, Channel) {
                visit [target];
            }
        }
        # <<<HOLE
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
