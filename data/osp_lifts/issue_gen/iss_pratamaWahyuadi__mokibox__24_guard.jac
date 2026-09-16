# pratamaWahyuadi/mokibox#24 — comments, replies, cascade delete via OSP walkers

node Video { has ready: bool = True; }
node Comment {
  has cid: str;
  has author: str;
  has content: str;
  has created_at: int;
}
edge reply_to {}
edge posted_on {}
edge owns {}

def _check_content(content: str) -> bool {
    return len(content) >= 1 and len(content) <= 1000;
}

walker InsertComment {
  has video_id: str;
  has cid: str;
  has author: str;
  has content: str;
  has ts: int;
  has ok: bool = False;
  can go with root entry {
    v: Video | None = None;
    for vv in [root ->:owns:->][?:Video] {
      if vv.cid == self.video_id { v = vv; }
    }
    if v is None or not v.ready or not _check_content(self.content) {
      disengage;
    }
    c = Comment(cid=self.cid, author=self.author, content=self.content, created_at=self.ts);
    here ++> c;
    c +>:posted_on:+> v;
    self.ok = True;
    print("inserted " + self.cid);
    visit [v];
  }
  can notify with Video entry {
    print("notify video owner type=comment");
    disengage;
  }
}

walker ReplyComment {
  has parent_id: str;
  has cid: str;
  has author: str;
  has content: str;
  has ts: int;
  has ok: bool = False;
  claimed: dict[str, bool] = {};
  can go with root entry {
    par: Comment | None = None;
    for c in [root ->:owns:->][?:Comment] {
      if c.cid == self.parent_id { par = c; }
    }
    if par is None or not _check_content(self.content) { disengage; }
    c = Comment(cid=self.cid, author=self.author, content=self.content, created_at=self.ts);
    here ++> c;
    par +>:reply_to:+> c;
    self.ok = True;
    print("reply " + self.cid);
    visit [par] else { disengage; }
  }
  can walk_up with Comment entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    print("notify parent author " + here.author);
    visit [here ->:reply_to:->][?:Comment] else { disengage; }
  }
}

walker CountSubtree {
  has target: str;
  has count: int = 0;
  claimed: dict[str, bool] = {};
  can go with root entry {
    found: list[Comment] = [];
    for c in [root ->:owns:->][?:Comment] {
      if c.cid == self.target { found.append(c); }
    }
    if len(found) == 0 { disengage; }
    visit [found[0]];
  }
  can collect with Comment entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.count = self.count + 1;
    visit [here ->:reply_to:->][?:Comment];
  }
}

walker ListComments {
  has video_id: str;
  has cursor: int = 0;
  has out: list[tuple[int, str]] = [];
  can go with root entry {
    for c in [root <-:posted_on:-][?:Comment] {
      if self.cursor > 0 and c.created_at >= self.cursor { skip; }
      self.out.append((c.created_at, c.cid));
    }
    self.out = sorted(self.out);
    for item in self.out { print(item[1]); }
    disengage;
  }
}

walker DeleteComment {
  has target: str;
  has ok: bool = False;
  claimed: dict[str, bool] = {};
  can go with root entry {
    found: list[Comment] = [];
    for c in [root ->:owns:->][?:Comment] {
      if c.cid == self.target { found.append(c); }
    }
    if len(found) == 0 { disengage; }
    self.ok = True;
    print("deleting subtree of " + self.target);
    visit [found[0]];
  }
  can sweep with Comment entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    print("delete " + here.cid);
    visit [here ->:reply_to:->][?:Comment];
  }
}

def insert_comment(root_node: root, video_id: str, cid: str, author: str, content: str, ts: int) -> bool {
    w = root_node spawn InsertComment(video_id=video_id, cid=cid, author=author, content=content, ts=ts);
    return w.ok;
}

def reply_comment(root_node: root, parent_id: str, cid: str, author: str, content: str, ts: int) -> bool {
    w = root_node spawn ReplyComment(parent_id=parent_id, cid=cid, author=author, content=content, ts=ts);
    return w.ok;
}

def count_subtree(root_node: root, target: str) -> int {
    w = root_node spawn CountSubtree(target=target);
    return w.count;
}

def list_comments(root_node: root, video_id: str, cursor: int = 0) -> list[tuple[int, str]] {
    w = root_node spawn ListComments(video_id=video_id, cursor=cursor);
    return w.out;
}

def delete_comment(root_node: root, target: str) -> bool {
    w = root_node spawn DeleteComment(target=target);
    return w.ok;
}

test "insert and count replies" {
  root ++> MockRoot();
  assert insert_comment(root, "v1", "c1", "alice", "hello", 10);
  assert reply_comment(root, "c1", "c2", "bob", "hi back", 11);
  assert reply_comment(root, "c2", "c3", "carol", "nested", 12);
  assert count_subtree(root, "c1") == 3;
  assert count_subtree(root, "c2") == 2;
  assert count_subtree(root, "c3") == 1;
  assert count_subtree(root, "missing") == 0;
}

test "insert validation" {
  assert insert_comment(root, "nonesuch", "cx", "a", "body", 1) == False;
  assert insert_comment(root, "v1", "cy", "a", "", 1) == False;
}

test "list comments sorted with cursor" {
  root ++> MockRoot();
  insert_comment(root, "v1", "l3", "a", "c", 30);
  insert_comment(root, "v1", "l1", "a", "c", 10);
  insert_comment(root, "v1", "l2", "a", "c", 20);
  assert list_comments(root, "v1") == [(10, "l1"), (20, "l2"), (30, "l3")];
  assert list_comments(root, "v1", cursor=20) == [(10, "l1")];
  assert list_comments(root, "ghost") == [];
}

test "diamond replies count once" {
  root ++> MockRoot();
  insert_comment(root, "v1", "d1", "a", "c", 1);
  reply_comment(root, "d1", "d2", "b", "c", 2);
  reply_comment(root, "d1", "d3", "c", "c", 3);
  # adversarial order: revisit d1 before deeper first-visits
  reply_comment(root, "d3", "d4", "d", "c", 4);
  assert count_subtree(root, "d1") == 4;
}

test "delete returns ok for unknown" {
  root ++> MockRoot();
  assert delete_comment(root, "nope") == False;
}

test "delete subtree root found" {
  root ++> MockRoot();
  insert_comment(root, "v1", "z1", "a", "c", 5);
  reply_comment(root, "z1", "z2", "b", "c", 6);
  assert delete_comment(root, "z1");
  assert delete_comment(root, "z1") == False;
}

# appended fixture seed used by the tests above
node MockRoot {}
