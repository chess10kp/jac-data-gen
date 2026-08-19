"""RL driver (graph): social_graph.join_channel.act.

Origin: this_is_jac/littlex/social_graph.jac. `join_channel` subclasses
`find_channel` (resolves the target Channel by jid) and adds the caller's Member
edge on entry. The marked body is `act`; the entry block joins a fixed channel
twice (idempotent) and prints the deterministic membership result.
"""

edge Member {}
node Profile { has username: str = ""; }
node Channel {
    has name: str = "", creator_username: str = "";
}

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

walker join_channel(find_channel) {
    can act with Channel entry {
        # >>>HOLE id="sg_join_channel_act" instruction="Implement the act ability (walker join_channel, on Channel entry). Only act when jid(here) == self.channel_id. Find the caller's Profile via [root-->[?:Profile]][0]; if there is no existing Member edge from that profile to here, create one (here is the channel). Then report {'success': True} and disengage. Make it idempotent: do not add a duplicate Member edge."
        if jid(here) == self.channel_id {
            me = [root-->[?:Profile]][0];
            if not [edge me->:Member:->here] {
                me +>: Member() :+> here;
            }
            report {"success": True};
            disengage;
        }
        # <<<HOLE
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    c = (root ++> Channel(name="jacdevs", creator_username="bob"))[0];
    cid = jid(c);
    r1 = root spawn join_channel(channel_id=cid);
    r2 = root spawn join_channel(channel_id=cid);
    print("join1:", r1.reports[0]);
    print("join2_idempotent:", r2.reports[0]);
    print("member_count:", len([c<-:Member:<-[?:Profile]]));
    print("is_member:", len([edge p->:Member:->c]) > 0);
}
