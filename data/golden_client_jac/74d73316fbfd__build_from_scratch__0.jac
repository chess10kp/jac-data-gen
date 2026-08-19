walker follow_user(find_profile) {
    can act with Profile entry {
        if jid(here) == self.target_id {
            me = [root-->[?:Profile]][0];
            here +>: Follow() :+> me;
            report {"success": True};
            disengage;
        }
    }
}
