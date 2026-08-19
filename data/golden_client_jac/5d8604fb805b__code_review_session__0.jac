node Todo { has parent_id: str = ""; }

walker:priv DeleteWithChildren {
    has parent_id: str;

    can search with Root entry {
        visit [-->];
    }

    can delete with Todo entry {
        # Decide before we descend or delete
        should_delete = (jid(here) == self.parent_id
                         or here.parent_id == self.parent_id);
        # Descend FIRST so nested todos remain reachable
        visit [-->];
        if should_delete {
            del here;
        }
    }
}
