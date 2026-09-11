"""Social platform, lifted to OSP.

Communities nest via Subcommunity edges; users join via MemberOf cross-links;
the follow graph is Follows edges and blocks are symmetric Blocks edges.
Walkers replace the community-tree stack walk and the follow-graph BFS.
Cycle policy: the source capped the BFS with a visited set; that guard set
is domain logic and survives. Blocking severs Follows edges (two-phase:
collect pair, then disconnect outside any walk).
"""
node Community {
    has cid: str;
}

node User {
    has uid: str;
}

"""Community hierarchy: parent +>:Subcommunity:+> child."""
edge Subcommunity {}

"""Membership cross-link: user joined community."""
edge MemberOf {}

"""Follow graph edge."""
edge Follows {}

"""Symmetric block edge."""
edge Blocks {}

walker CommunityCensus {
    """Descends Subcommunity edges and collects member uids via forward
    MemberOf links. Guard sets keep shared sub-communities once-only."""
    has members: set[str] = set();
    has claimed: dict[str, bool] = {};
    has include_sub: bool = True;

    can step with User entry {
        self.members.add(here.uid);
    }
    can census with Community entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        visit [->:MemberOf:->];
        if self.include_sub {
            visit [->:Subcommunity:->];
        }
    }
}

walker CircleWalker {
    """BFS-equivalent closure over Follows edges with a visited guard."""
    has origin: str;
    has cap: int;
    has found: set[str] = set();
    has claimed: dict[str, bool] = {};

    can step with User entry {
        if here.uid in self.claimed {
            skip;
        }
        self.claimed[here.uid] = True;
        if here.uid != self.origin {
            # source caps on len(seen) which includes the origin, so at
            # most max_size-1 others are ever collected
            if len(self.found) >= self.cap - 1 {
                disengage;
            }
            self.found.add(here.uid);
        }
        visit [->:Follows:->];
    }
}

obj SocialNetwork {
    """Compatibility facade. Community ids and user ids are public API
    currency; lookup maps are domain state."""
    has by_cid: dict[str, Community] = {};
    has by_uid: dict[str, User] = {};

    def add_community(cid: str, parent: str | None = None) -> str {
        if cid in self.by_cid {
            raise ValueError("duplicate community " + cid);
        }
        c := Community(cid=cid);
        if parent is not None {
            p = self.by_cid[parent];
            p +>:Subcommunity:+> c;
        }
        self.by_cid[cid] = c;
        return cid;
    }

    def join(uid: str, cid: str) -> None {
        # repeat membership dedups: joining twice is a no-op
        u = self._user(uid);
        c = self.by_cid[cid];
        members: list[User] = [c <-:MemberOf:<-];
        if u not in members {
            c +>:MemberOf:+> u;
        }
    }

    def follow(a: str, b: str) -> None {
        # source requires prior join on both ends (follows/blocks maps
        # are only created by join); no auto-create
        if a not in self.by_uid or b not in self.by_uid {
            raise KeyError(a);
        }
        ua = self._user(a);
        ub = self._user(b);
        blocked: list[User] = [ua ->:Blocks:->];
        if ub in blocked {
            raise ValueError("blocked");
        }
        ua +>:Follows:+> ub;
    }

    """Blocking propagates: collect the pair's follow edges, then sever
    them outside any walk."""
    def block(a: str, b: str) -> None {
        ua = self._user(a);
        ub = self._user(b);
        ua +>:Blocks:+> ub;
        ub +>:Blocks:+> ua;
        a_follows: list[User] = [ua ->:Follows:->];
        b_follows: list[User] = [ub ->:Follows:->];
        if ub in a_follows {
            ua del ->:Follows:-> ub;
        }
        if ua in b_follows {
            ub del ->:Follows:-> ua;
        }
    }

    def members_within(cid: str, include_sub: bool = True) -> list[str] {
        w = self.by_cid[cid] spawn CommunityCensus(include_sub=include_sub);
        return sorted(w.members);
    }

    def circle(uid: str, max_size: int = 50) -> list[str] {
        w = self._user(uid) spawn CircleWalker(origin=uid, cap=max_size);
        return sorted(w.found);
    }

    def common_follows(a: str, b: str) -> list[str] {
        fa: list[User] = [self._user(a) ->:Follows:->];
        fb: list[User] = [self._user(b) ->:Follows:->];
        both: set[str] = {u.uid for u in fa if u in fb};
        return sorted(both);
    }

    def _user(uid: str) -> User {
        u = self.by_uid.get(uid);
        if u is None {
            u = User(uid=uid);
            self.by_uid[uid] = u;
        }
        return u;
    }
}
