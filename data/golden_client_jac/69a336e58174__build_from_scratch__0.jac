walker join_channel(find_channel) {
    can act with Channel entry {
        if jid(here) == self.channel_id {
            me = [root-->[?:Profile]][0];
            me +>: Member() :+> here;
            report {"success": True};
            disengage;
        }
    }
}
