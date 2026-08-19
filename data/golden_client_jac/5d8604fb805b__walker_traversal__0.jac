walker:priv DeleteWithChildren {
    has parent_id: str;

    can search with Root entry {
        visit [-->];
    }

    can delete with Todo entry {
        # Delete if this is the target or a child of the target
        if jid(here) == self.parent_id or here.parent_id == self.parent_id {
            del here;
        }
    }
}
