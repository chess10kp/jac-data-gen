"""join_channel.act: idempotently add a Member edge from the caller to the channel (no duplicates), then report success."""

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
        if jid(here) == self.channel_id {
            me = [root-->[?:Profile]][0];
            if not [edge me->:Member:->here] {
                me +>: Member() :+> here;
            }
            report {"success": True};
            disengage;
        }
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
