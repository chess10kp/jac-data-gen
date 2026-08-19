edge Block {}

walker block_user(find_profile) {
    can act with Root entry {
        me = [root-->[?:Profile]][0];
        me +>:Block():+> here;
        report {"success": True};
        disengage;
    }
}
