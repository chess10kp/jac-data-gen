"""Synthetic org-tree traversal for F3-Nation/f3-nation#917."""

node Org {
    has org_id: str;
    has org_type: str;
    has grants: dict[str, bool] = {};
}

edge Parent {}

obj OrgIndex {
    has by_id: dict[str, Org] = {};
    has user_orgs: dict[str, str] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has depth: dict[str, int] = {};
    has found: list[Org] = [];

    can climb with Org entry {
        if here.org_id in self.claimed {
            skip;
        }
        self.claimed[here.org_id] = True;
        print("ancestor " + here.org_id);
        self.found.append(here);

        depth_now: int = 0;
        if here.org_id in self.depth {
            depth_now = self.depth[here.org_id];
        }
        if depth_now < 20 {
            for parent in [here ->:Parent:->][?:Org] {
                self.depth[parent.org_id] = depth_now + 1;
                visit :0: [parent];
            }
        }
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has depth: dict[str, int] = {};
    has found: list[Org] = [];

    can descend with Org entry {
        if here.org_id in self.claimed {
            skip;
        }
        self.claimed[here.org_id] = True;
        print("descendant " + here.org_id);
        self.found.append(here);

        depth_now: int = 0;
        if here.org_id in self.depth {
            depth_now = self.depth[here.org_id];
        }
        if depth_now < 20 {
            for child in [here <-:Parent:<-][?:Org] {
                self.depth[child.org_id] = depth_now + 1;
                visit :0: [child];
            }
        }
    }
}

def orgById(store: OrgIndex, org_id: str) -> Org | None {
    if org_id in store.by_id {
        return store.by_id[org_id];
    }
    return None;
}

def orgForUser(store: OrgIndex, user_id: str) -> Org | None {
    if user_id in store.user_orgs {
        return orgById(store, store.user_orgs[user_id]);
    }
    return None;
}

def checkHasRoleOnOrg(
    store: OrgIndex,
    user_id: str,
    org_id: str,
    role: str
) -> bool {
    target = orgById(store, org_id);
    if target == None {
        return False;
    }

    key: str = user_id + "|" + role;
    w = target spawn AncestorWalk();
    for org in w.found {
        if key in org.grants {
            if org.grants[key] {
                return True;
            }
        }
    }
    return False;
}

def getEditableOrgIdsForUser(
    store: OrgIndex,
    user_id: str
) -> list[str] {
    user_org = orgForUser(store, user_id);
    ids: list[str] = [];
    if user_org == None {
        return ids;
    }

    w = user_org spawn DescendantWalk();
    for org in w.found {
        ids.append(org.org_id);
    }
    return sorted(ids);
}

def getDescendantOrgIds(
    store: OrgIndex,
    org_id: str
) -> list[str] {
    target = orgById(store, org_id);
    ids: list[str] = [];
    if target == None {
        return ids;
    }

    w = target spawn DescendantWalk();
    for org in w.found {
        if org.org_id != org_id {
            ids.append(org.org_id);
        }
    }
    return sorted(ids);
}
