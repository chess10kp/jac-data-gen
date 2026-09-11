"""Social platform: communities plus a follow graph with block propagation.

Communities nest into a tree; users join communities and follow each other.
Blocking a user severs follows in both directions, and community membership
lookups must aggregate across nested sub-communities.

Hand-rolled machinery:
- parent/children pointers over the community tree (C1)
- follow/block adjacency dicts with a deque BFS over the follow graph (C2)

Uses collections.deque for the frontier queue.
"""
import from collections { deque }
class Community {
    def init(self: Community, cid: Any, parent: Any = None) -> object {
        self.cid = cid;
        self.parent = parent;
        self.children = [];
        self.members = [];
    }
}
class SocialNetwork {
    def init(self: SocialNetwork) -> object {
        self.communities = {};
        self.users = {};
        self.follows = {};
        self.blocks = {};
    }
    def add_community(self: SocialNetwork, cid: Any, parent: Any = None) -> object {
        if (cid in self.communities) {
            raise ValueError("duplicate community");
        }
        p = self.communities[parent] if (parent is not None) else None;
        c = Community(cid, p);
        c.members = [];
        if (p is not None) {
            p.children.append(c);
        }
        self.communities[cid] = c;
        return cid;
    }
    def join(self: SocialNetwork, uid: Any, cid: Any) -> object {
        if (uid not in self.users) {
            self.users[uid] = `set();
            self.follows[uid] = `set();
            self.blocks[uid] = `set();
        }
        if (cid not in self.communities) {
            raise KeyError(cid);
        }
        if (uid not in self.communities[cid].members) {
            self.communities[cid].members.append(uid);
            self.users[uid].add(cid);
        }
    }
    def follow(self: SocialNetwork, a: Any, b: Any) -> object {
        if ((b in self.blocks[a]) or (a in self.blocks[b])) {
            raise ValueError("blocked");
        }
        self.follows[a].add(b);
    }
    """Blocking propagates: sever follows in both directions."""
    def block(self: SocialNetwork, a: Any, b: Any) -> object {
        self.blocks[a].add(b);
        self.blocks[b].add(a);
        self.follows[a].discard(b);
        self.follows[b].discard(a);
    }
    """Members of cid, optionally across the whole sub-tree."""
    def members_within(
        self: SocialNetwork, cid: Any, include_sub: Any = True
    ) -> object {
        out = [];
        seen = `set();
        stack = [cid];
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            mem = self.communities[cur].members as list;
            out.extend(mem);
            if include_sub {
                kids = self.communities[cur].children as list;
                stack.extend(kids);
            }
        }
        return sorted(`set(out));
    }
    """Transitive follow closure (BFS, cycle safe, capped)."""
    def circle(self: SocialNetwork, uid: Any, max_size: Any = 50) -> object {
        seen = {uid};
        q = deque([uid]);
        while (q and (len(seen) < max_size)) {
            cur = q.popleft();
            fset = self.follows.get(cur, set()) as set;
            for n in fset {
                if (n not in seen) {
                    seen.add(n);
                    q.append(n);
                }
            }
        }
        seen.discard(uid);
        return sorted(seen);
    }
    def common_follows(self: SocialNetwork, a: Any, b: Any) -> object {
        inter = (self.follows[a] & self.follows[b]) as set;
        return sorted(inter);
    }
}

