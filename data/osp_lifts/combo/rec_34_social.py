"""Social platform: communities plus a follow graph with block propagation.

Communities nest into a tree; users join communities and follow each other.
Blocking a user severs follows in both directions, and community membership
lookups must aggregate across nested sub-communities.

Hand-rolled machinery:
- parent/children pointers over the community tree (C1)
- follow/block adjacency dicts with a deque BFS over the follow graph (C2)

Uses collections.deque for the frontier queue.
"""
from collections import deque


class Community:
    def __init__(self, cid, parent=None):
        self.cid = cid
        self.parent = parent
        self.children = []
        self.members = []


class SocialNetwork:
    def __init__(self):
        self.communities = {}  # cid -> Community
        self.users = {}        # uid -> set of joined cids
        self.follows = {}      # uid -> set of followed uids
        self.blocks = {}       # uid -> set of blocked uids (both directions)

    def add_community(self, cid, parent=None):
        if cid in self.communities:
            raise ValueError("duplicate community " + cid)
        p = self.communities[parent] if parent is not None else None
        c = Community(cid, p)
        c.members = []
        if p is not None:
            p.children.append(c)
        self.communities[cid] = c
        return cid

    def join(self, uid, cid):
        if uid not in self.users:
            self.users[uid] = set()
            self.follows[uid] = set()
            self.blocks[uid] = set()
        if cid not in self.communities:
            raise KeyError(cid)
        if uid not in self.communities[cid].members:
            self.communities[cid].members.append(uid)
            self.users[uid].add(cid)

    def follow(self, a, b):
        if b in self.blocks[a] or a in self.blocks[b]:
            raise ValueError("blocked")
        self.follows[a].add(b)

    def block(self, a, b):
        """Blocking propagates: sever follows in both directions."""
        self.blocks[a].add(b)
        self.blocks[b].add(a)
        self.follows[a].discard(b)
        self.follows[b].discard(a)

    def members_within(self, cid, include_sub=True):
        """Members of cid, optionally across the whole sub-tree."""
        out = []
        seen = set()
        stack = [cid]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            out.extend(self.communities[cur].members)
            if include_sub:
                stack.extend(c.cid for c in self.communities[cur].children)
        return sorted(set(out))

    def circle(self, uid, max_size=50):
        """Transitive follow closure (BFS, cycle safe, capped)."""
        seen = {uid}
        q = deque([uid])
        while q and len(seen) < max_size:
            cur = q.popleft()
            for n in self.follows.get(cur, set()):
                if n not in seen:
                    seen.add(n)
                    q.append(n)
        seen.discard(uid)
        return sorted(seen)

    def common_follows(self, a, b):
        return sorted(self.follows[a] & self.follows[b])
