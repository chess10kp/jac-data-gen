node Folder { has fid: str; }
node Document { has did: str; }
node User { has uid: str; }
node Group { has gid: str; }
node AclRule { has subject_id: str; has permission: str; has priority: int; }
node CacheNode { has store: dict[str, str] = {}; }
edge ParentEdge {}
edge InFolder {}
edge Grant {}
edge Member {}

walker AncestorPerm {
    has claimed: dict[str, bool] = {};
    has user_id: str = "";
    has groups: dict[str, bool] = {};
    has best_perm: str = "NONE";
    has best_prio: int = -1;
    can resolve_doc with Document entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        print("visit doc " + here.did);
        for gr in [here ->:Grant:->][?:AclRule] {
            if gr.subject_id == self.user_id {
                if gr.priority > self.best_prio { self.best_prio = gr.priority; self.best_perm = gr.permission; }
            } else {
                if gr.subject_id in self.groups {
                    if gr.priority > self.best_prio { self.best_prio = gr.priority; self.best_perm = gr.permission; }
                }
            }
        }
        nxt: list[Folder] = [here ->:InFolder:->][?:Folder];
        if len(nxt) > 0 { visit :0: nxt; } else { disengage; }
    }
    can resolve_folder with Folder entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("visit folder " + here.fid);
        for gr in [here ->:Grant:->][?:AclRule] {
            if gr.subject_id == self.user_id {
                if gr.priority > self.best_prio { self.best_prio = gr.priority; self.best_perm = gr.permission; }
            } else {
                if gr.subject_id in self.groups {
                    if gr.priority > self.best_prio { self.best_prio = gr.priority; self.best_perm = gr.permission; }
                }
            }
        }
        pars: list[Folder] = [here ->:ParentEdge:->][?:Folder];
        if len(pars) > 0 { visit :0: pars; } else { disengage; }
    }
}
walker GroupCollect {
    has claimed: dict[str, bool] = {};
    has gids: dict[str, bool] = {};
    can collect with User entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        print("collect groups " + here.uid);
        for g in [here ->:Member:->][?:Group] { self.gids[g.gid] = True; }
        disengage;
    }
}
walker Descendants {
    has claimed: dict[str, bool] = {};
    has docs: list[str] = [];
    can down_folder with Folder entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("descend " + here.fid);
        for d in [here <-:InFolder:<-][?:Document] { self.docs.append(d.did); }
        kids: list[Folder] = [here <-:ParentEdge:<-][?:Folder];
        if len(kids) > 0 { visit :0: kids; } else { disengage; }
    }
}
walker DemoWalker {
    has msg: str = "demo ready";
    can run with CacheNode entry { print(self.msg); disengage; }
}
def create_folder(fid: str, parent: Folder | None = None) -> Folder {
    nd = Folder(fid=fid);
    root ++> nd;
    if parent is not None { nd +>:ParentEdge:+> parent; }
    return nd;
}
def create_document(did: str, folder: Folder) -> Document {
    nd = Document(did=did);
    root ++> nd;
    nd +>:InFolder:+> folder;
    return nd;
}
def create_user(uid: str) -> User {
    nd = User(uid=uid);
    root ++> nd;
    return nd;
}
def create_group(gid: str) -> Group {
    nd = Group(gid=gid);
    root ++> nd;
    return nd;
}
def add_member(user: User, group: Group) { user +>:Member:+> group; }
def grant_on_folder(folder: Folder, subject_id: str, permission: str, priority: int) {
    r = AclRule(subject_id=subject_id, permission=permission, priority=priority);
    root ++> r;
    folder +>:Grant:+> r;
}
def grant_on_document(doc: Document, subject_id: str, permission: str, priority: int) {
    r = AclRule(subject_id=subject_id, permission=permission, priority=priority);
    root ++> r;
    doc +>:Grant:+> r;
}
def check_permission(tenant_id: str, user: User, doc: Document, cache: CacheNode) -> str {
    key: str = tenant_id + ":" + user.uid + ":" + doc.did;
    if key in cache.store { print("cache hit " + key); return cache.store[key]; }
    gc = user spawn GroupCollect();
    groups: dict[str, bool] = gc.gids;
    pr = doc spawn AncestorPerm(user_id=user.uid, groups=groups);
    perm: str = pr.best_perm;
    cache.store[key] = perm;
    print("cache miss " + perm);
    return perm;
}
def invalidate_folder(folder: Folder, tenant_id: str, cache: CacheNode) {
    w = folder spawn Descendants();
    doomed: dict[str, bool] = {};
    for d in w.docs { doomed[d] = True; }
    to_del: list[str] = [];
    for k in cache.store {
        for did in doomed { if did in k { to_del.append(k); } }
    }
    for k in to_del { del cache.store[k]; }
    print("invalidated");
}
with entry {
    c = CacheNode(store={});
    root ++> c;
    w = c spawn DemoWalker(msg="acl engine ready");
}
